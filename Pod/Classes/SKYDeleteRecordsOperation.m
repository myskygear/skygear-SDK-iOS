//
//  SKYDeleteRecordsOperation.m
//  SKYKit
//
//  Copyright 2015 Oursky Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SKYDeleteRecordsOperation.h"
#import "SKYOperationSubclass.h"

#import "SKYDataSerialization.h"
#import "SKYError.h"
#import "SKYRecordResponseDeserializer.h"
#import "SKYRecordSerialization.h"

@implementation SKYDeleteRecordsOperation

- (instancetype)initWithRecordType:(NSString *)recordType
                 recordIDsToDelete:(NSArray<NSString *> *)recordIDs
{
    self = [super init];
    if (self) {
        self.recordType = recordType; // copy
        self.recordIDs = recordIDs;   // copy
    }
    return self;
}

+ (instancetype)operationWithRecordType:(NSString *)recordType
                      recordIDsToDelete:(NSArray<NSString *> *)recordIDs
{
    return [[self alloc] initWithRecordType:recordType recordIDsToDelete:recordIDs];
}

- (void)prepareForRequest
{
    NSMutableArray *deprecatedIDs = [NSMutableArray array];
    [self.recordIDs enumerateObjectsUsingBlock:^(NSString *recordID, NSUInteger idx, BOOL *stop) {
        [deprecatedIDs addObject:SKYRecordConcatenatedID(self.recordType, recordID)];
    }];

    NSMutableDictionary *payload = [@{
        @"ids" : deprecatedIDs,
        @"recordType" : self.recordType,
        @"recordIDs" : self.recordIDs,
        @"database_id" : self.database.databaseID,
    } mutableCopy];
    if (self.atomic) {
        payload[@"atomic"] = @YES;
    }

    self.request = [[SKYRequest alloc] initWithAction:@"record:delete" payload:payload];
    self.request.accessToken = self.container.auth.currentAccessToken;
}

- (NSArray *)processResultArray:(NSArray *)result error:(NSError **)operationError
{
    __block BOOL erroneousResponse = NO;

    SKYRecordResponseDeserializer *deserializer = [[SKYRecordResponseDeserializer alloc] init];
    NSMutableDictionary<NSString *, NSError *> *errorsByID = [NSMutableDictionary dictionary];
    [result enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        [deserializer deserializeResponseDictionary:obj
                                              block:^(NSString *recordType, NSString *recordID,
                                                      SKYRecord *record, NSError *error) {
                                                  if (!(recordType && recordID)) {
                                                      erroneousResponse = YES;
                                                      *stop = YES;
                                                      return;
                                                  }

                                                  if (error) {
                                                      [errorsByID setObject:error forKey:recordID];
                                                  }
                                              }];
    }];

    if (erroneousResponse) {
        if (operationError) {
            *operationError =
                [self.errorCreator errorWithCode:SKYErrorInvalidData
                                         message:@"Missing `_id` or not in correct format."];
        }
        return nil;
    }

    if (operationError) {
        if ([errorsByID count] > 0) {
            *operationError = [self.errorCreator partialErrorWithPerItemDictionary:errorsByID];
        } else {
            *operationError = nil;
        }
    }

    NSMutableArray *deletedRecordIDs = [NSMutableArray array];
    [self.recordIDs enumerateObjectsUsingBlock:^(NSString *recordID, NSUInteger idx, BOOL *stop) {
        NSError *error = errorsByID[recordID];

        if (!error) {
            [deletedRecordIDs addObject:recordID];
        }

        if (self.perRecordCompletionBlock) {
            self.perRecordCompletionBlock(recordID, error);
        }
    }];

    return deletedRecordIDs;
}

- (void)handleRequestError:(NSError *)error
{
    if (self.deleteRecordsCompletionBlock) {
        self.deleteRecordsCompletionBlock(nil, error);
    }
}

- (void)handleResponse:(SKYResponse *)response
{
    NSArray *resultArray = nil;
    NSError *error = nil;
    NSArray *responseArray = response.responseDictionary[@"result"];
    if ([responseArray isKindOfClass:[NSArray class]]) {
        resultArray = [self processResultArray:responseArray error:&error];
    } else {
        error = [self.errorCreator errorWithCode:SKYErrorBadResponse
                                         message:@"Result is not an array or not exists."];
    }

    if (self.deleteRecordsCompletionBlock) {
        self.deleteRecordsCompletionBlock(resultArray, error);
    }
}

@end
