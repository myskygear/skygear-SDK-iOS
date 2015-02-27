//
//  ODContainerTests.m
//  ODKit
//
//  Created by Patrick Cheung on 27/2/15.
//  Copyright (c) 2015 Kwok-kuen Cheung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ODKit/ODKit.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "ODContainer_Private.h"

SpecBegin(ODContainer)

describe(@"save current user", ^{
    it(@"fetch record", ^{
        ODContainer *container = [[ODContainer alloc] init];
        [container updateWithUserRecordID:[[ODUserRecordID alloc] initWithRecordName:@"user1"]
                              accessToken:[[ODAccessToken alloc] initWithTokenString:@"accesstoken1"]];

        container = [[ODContainer alloc] init];
        expect(container.currentUserRecordID.recordName).to.equal(@"user1");
        expect(container.currentAccessToken.tokenString).to.equal(@"accesstoken1");
    });
    
    it(@"update with nil", ^{
        ODContainer *container = [[ODContainer alloc] init];
        [container updateWithUserRecordID:nil
                              accessToken:nil];
        
        container = [[ODContainer alloc] init];
        expect(container.currentUserRecordID).to.beNil();
        expect(container.currentAccessToken).to.beNil();
    });
    
    afterEach(^{
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    });
});

SpecEnd