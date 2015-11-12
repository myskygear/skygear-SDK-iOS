//
//  SKYRecordID.h
//  askq
//
//  Created by Kenji Pa on 20/1/15.
//  Copyright (c) 2015 Rocky Chan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKYRecordID : NSObject <NSCopying, NSSecureCoding>

/**
 Instantiates an instance of SKYRecordID with a random record name.
 */
- (instancetype)init __deprecated;
- (instancetype)initWithRecordName:(NSString *)recordName __deprecated;

- (instancetype)initWithRecordType:(NSString *)type;
- (instancetype)initWithCanonicalString:(NSString *)canonicalString;
- (instancetype)initWithRecordType:(NSString *)type
                              name:(NSString *)recordName NS_DESIGNATED_INITIALIZER;

+ (instancetype)recordIDWithRecordType:(NSString *)type;
+ (instancetype)recordIDWithCanonicalString:(NSString *)canonicalString;
+ (instancetype)recordIDWithRecordType:(NSString *)type name:(NSString *)recordName;

- (BOOL)isEqualToRecordID:(SKYRecordID *)recordID;

@property (nonatomic, readonly, strong) NSString *recordType;
@property (nonatomic, readonly, strong) NSString *recordName;
@property (nonatomic, readonly, strong) NSString *canonicalString;

@end
