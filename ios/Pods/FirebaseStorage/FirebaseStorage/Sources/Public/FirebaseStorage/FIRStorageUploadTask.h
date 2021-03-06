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

#import <Foundation/Foundation.h>

#import "FIRStorageObservableTask.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * FIRStorageUploadTask implements resumable uploads to a file in Firebase Storage.
 * Uploads can be returned on completion with a completion callback, and can be monitored
 * by attaching observers, or controlled by calling FIRStorageTask#pause, FIRStorageTask#resume,
 * or FIRStorageTask#cancel.
 * Uploads can take NSData in memory, or an NSURL to a file on disk.
 * Uploads are performed on a background queue, and callbacks are raised on the developer
 * specified callbackQueue in FIRStorage, or the main queue if left unspecified.
 * Currently all uploads must be initiated and managed on the main queue.
 */
NS_SWIFT_NAME(StorageUploadTask)
@interface FIRStorageUploadTask : FIRStorageObservableTask <FIRStorageTaskManagement>

@end

NS_ASSUME_NONNULL_END
