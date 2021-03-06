/*
 * Copyright 2019 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FIRInstanceIDTokenOperation.h"

#import "FirebaseInstallations/Source/Library/Private/FirebaseInstallationsInternal.h"

#import "FIRInstanceIDCheckinPreferences.h"
#import "FIRInstanceIDLogger.h"
#import "FIRInstanceIDUtilities.h"
#import "NSError+FIRInstanceID.h"

static const NSInteger kFIRInstanceIDPlatformVersionIOS = 2;

// Scope parameter that defines the service using the token
static NSString *const kFIRInstanceIDParamScope = @"X-scope";
// Defines the SDK version
static NSString *const kFIRInstanceIDParamFCMLibVersion = @"X-cliv";

@interface FIRInstanceIDTokenOperation () {
  BOOL _isFinished;
  BOOL _isExecuting;
}

@property(nonatomic, readwrite, strong) FIRInstanceIDCheckinPreferences *checkinPreferences;
@property(nonatomic, readwrite, strong) NSString *instanceID;

@property(atomic, strong) NSURLSessionDataTask *dataTask;
@property(readonly, strong)
    NSMutableArray<FIRInstanceIDTokenOperationCompletion> *completionHandlers;

@property(atomic, strong, nullable) NSString *FISAuthToken;

// For testing only
@property(nonatomic, readwrite, copy) FIRInstanceIDURLRequestTestBlock testBlock;

@end

@implementation FIRInstanceIDTokenOperation

+ (NSURLSession *)sharedURLSession {
  static NSURLSession *tokenOperationSharedSession;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForResource = 60.0f;  // 1 minute
    tokenOperationSharedSession = [NSURLSession sessionWithConfiguration:config];
    tokenOperationSharedSession.sessionDescription = @"com.google.iid.tokens.session";
  });
  return tokenOperationSharedSession;
}

- (instancetype)initWithAction:(FIRInstanceIDTokenAction)action
           forAuthorizedEntity:(NSString *)authorizedEntity
                         scope:(NSString *)scope
                       options:(NSDictionary<NSString *, NSString *> *)options
            checkinPreferences:(FIRInstanceIDCheckinPreferences *)checkinPreferences
                    instanceID:(NSString *)instanceID {
  self = [super init];
  if (self) {
    _action = action;
    _authorizedEntity = [authorizedEntity copy];
    _scope = [scope copy];
    _options = [options copy];
    _checkinPreferences = checkinPreferences;
    _instanceID = instanceID;
    _completionHandlers = [NSMutableArray array];

    _isExecuting = NO;
    _isFinished = NO;
  }
  return self;
}

- (void)dealloc {
  _testBlock = nil;
  _authorizedEntity = nil;
  _scope = nil;
  _options = nil;
  _checkinPreferences = nil;
  _instanceID = nil;
  [_completionHandlers removeAllObjects];
  _completionHandlers = nil;
}

- (void)addCompletionHandler:(FIRInstanceIDTokenOperationCompletion)handler {
  [self.completionHandlers addObject:handler];
}

- (BOOL)isAsynchronous {
  return YES;
}

- (BOOL)isExecuting {
  return _isExecuting;
}

- (void)setExecuting:(BOOL)executing {
  [self willChangeValueForKey:@"isExecuting"];
  _isExecuting = executing;
  [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isFinished {
  return _isFinished;
}

- (void)setFinished:(BOOL)finished {
  [self willChangeValueForKey:@"isFinished"];
  _isFinished = finished;
  [self didChangeValueForKey:@"isFinished"];
}

- (void)start {
  if (self.isCancelled) {
    [self finishWithResult:FIRInstanceIDTokenOperationCancelled token:nil error:nil];
    return;
  }

  // Quickly validate whether or not the operation has all it needs to begin
  BOOL checkinfoAvailable = [self.checkinPreferences hasCheckinInfo];
  if (!checkinfoAvailable) {
    FIRInstanceIDErrorCode errorCode = kFIRInstanceIDErrorCodeRegistrarFailedToCheckIn;
    [self finishWithResult:FIRInstanceIDTokenOperationError
                     token:nil
                     error:[NSError errorWithFIRInstanceIDErrorCode:errorCode]];
    return;
  }

  [self setExecuting:YES];

  [[FIRInstallations installations]
      authTokenWithCompletion:^(FIRInstallationsAuthTokenResult *_Nullable tokenResult,
                                NSError *_Nullable error) {
        if (tokenResult.authToken.length > 0) {
          self.FISAuthToken = tokenResult.authToken;
          [self performTokenOperation];
        } else {
          [self finishWithResult:FIRInstanceIDTokenOperationError token:nil error:error];
        }
      }];
}

- (void)finishWithResult:(FIRInstanceIDTokenOperationResult)result
                   token:(nullable NSString *)token
                   error:(nullable NSError *)error {
  // Add a check to prevent this finish from being called more than once.
  if (self.isFinished) {
    return;
  }
  self.dataTask = nil;
  _result = result;
  // TODO(chliangGoogle): Call these in the main thread?
  for (FIRInstanceIDTokenOperationCompletion completionHandler in self.completionHandlers) {
    completionHandler(result, token, error);
  }

  [self setExecuting:NO];
  [self setFinished:YES];
}

- (void)cancel {
  [super cancel];
  [self.dataTask cancel];
  [self finishWithResult:FIRInstanceIDTokenOperationCancelled token:nil error:nil];
}

- (void)performTokenOperation {
}

- (NSMutableURLRequest *)tokenRequest {
  NSString *authHeader =
      [FIRInstanceIDTokenOperation HTTPAuthHeaderFromCheckin:self.checkinPreferences];
  return [[self class] requestWithAuthHeader:authHeader FISAuthToken:self.FISAuthToken];
}

#pragma mark - Request Construction
+ (NSMutableURLRequest *)requestWithAuthHeader:(NSString *)authHeaderString
                                  FISAuthToken:(NSString *)FISAuthToken {
  NSURL *url = [NSURL URLWithString:FIRInstanceIDRegisterServer()];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

  // Add HTTP headers
  [request setValue:authHeaderString forHTTPHeaderField:@"Authorization"];
  [request setValue:FIRInstanceIDAppIdentifier() forHTTPHeaderField:@"app"];
  if (FISAuthToken) {
    [request setValue:FISAuthToken forHTTPHeaderField:@"x-goog-firebase-installations-auth"];
  }
  request.HTTPMethod = @"POST";
  return request;
}

+ (NSMutableArray<NSURLQueryItem *> *)standardQueryItemsWithDeviceID:(NSString *)deviceID
                                                               scope:(NSString *)scope {
  NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:8];

  // E.g. X-osv=10.2.1
  NSString *systemVersion = FIRInstanceIDOperatingSystemVersion();
  [queryItems addObject:[NSURLQueryItem queryItemWithName:@"X-osv" value:systemVersion]];
  // E.g. device=
  if (deviceID) {
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"device" value:deviceID]];
  }
  // E.g. X-scope=fcm
  if (scope) {
    [queryItems addObject:[NSURLQueryItem queryItemWithName:kFIRInstanceIDParamScope value:scope]];
  }
  // E.g. plat=2
  NSString *platform = [NSString stringWithFormat:@"%ld", (long)kFIRInstanceIDPlatformVersionIOS];
  [queryItems addObject:[NSURLQueryItem queryItemWithName:@"plat" value:platform]];
  // E.g. app=com.myapp.foo
  NSString *appIdentifier = FIRInstanceIDAppIdentifier();
  [queryItems addObject:[NSURLQueryItem queryItemWithName:@"app" value:appIdentifier]];
  // E.g. app_ver=1.5
  NSString *appVersion = FIRInstanceIDCurrentAppVersion();
  [queryItems addObject:[NSURLQueryItem queryItemWithName:@"app_ver" value:appVersion]];
  // E.g. X-cliv=fiid-1.2.3
  NSString *fcmLibraryVersion =
      [NSString stringWithFormat:@"fiid-%@", FIRInstanceIDCurrentGCMVersion()];
  if (fcmLibraryVersion.length) {
    NSURLQueryItem *gcmLibVersion =
        [NSURLQueryItem queryItemWithName:kFIRInstanceIDParamFCMLibVersion value:fcmLibraryVersion];
    [queryItems addObject:gcmLibVersion];
  }

  return queryItems;
}

#pragma mark - HTTP Header

+ (NSString *)HTTPAuthHeaderFromCheckin:(FIRInstanceIDCheckinPreferences *)checkin {
  NSString *deviceID = checkin.deviceID;
  NSString *secret = checkin.secretToken;
  return [NSString stringWithFormat:@"AidLogin %@:%@", deviceID, secret];
}
@end
