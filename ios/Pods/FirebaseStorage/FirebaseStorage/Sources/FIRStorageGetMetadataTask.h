/*
 * Copyright 2017 Google
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

#import "FirebaseStorage/Sources/Public/FirebaseStorage/FIRStorageTask.h"

@class GTMSessionFetcherService;

NS_ASSUME_NONNULL_BEGIN

/**
 * Task which provides the ability to get metadata on an object in Firebase Storage.
 */
@interface FIRStorageGetMetadataTask : FIRStorageTask <FIRStorageTaskManagement>

- (instancetype)initWithReference:(FIRStorageReference *)reference
                   fetcherService:(GTMSessionFetcherService *)service
                    dispatchQueue:(dispatch_queue_t)queue
                       completion:(FIRStorageVoidMetadataError)completion;

@end

NS_ASSUME_NONNULL_END
