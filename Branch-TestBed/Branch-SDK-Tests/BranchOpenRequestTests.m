//
//  BranchOpenRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/19/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "Branch.h"
#import "BNCApplication+BNCTest.h"
#import "BranchOpenRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"
#import "BNCSystemObserver.h"

@interface BranchOpenRequestTests : BNCTestCase
@end

@implementation BranchOpenRequestTests

- (void)setUp {
    [super setUp];
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.installParams = nil;
    preferenceHelper.randomizedBundleToken = nil;
    preferenceHelper.checkedAppleSearchAdAttribution = NO;
    [preferenceHelper saveContentAnalyticsManifest:nil];
    [preferenceHelper synchronize];
}

- (void)testRequestBodyWithNoDeviceToken {
    NSString * const HARDWARE_ID = @"foo-hardware-id";
    NSNumber * const AD_TRACKING_SAFE = @YES;
    NSNumber * const IS_DEBUG = @YES;
    NSString * const BUNDLE_ID = @"foo-bundle-id";
    NSString * const APP_VERSION = @"foo-app-version";
    NSString * const OS = @"foo-os";
    NSString * const OS_VERSION = @"foo-os-version";
    NSString * const URI_SCHEME = @"foo-uri-scheme";
    NSString * const LINK_IDENTIFIER = @"foo-link-id";
    NSString * const RANDOMIZED_BUNDLE_TOKEN = @"foo-bundle-token";
    NSString * hardwareType = nil;

    BNCLogSetDisplayLevel(BNCLogLevelAll);
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    id systemObserverMock = OCMClassMock([BNCSystemObserver class]);
    [[[[systemObserverMock stub] ignoringNonObjectArgs] andReturn:HARDWARE_ID]
        getUniqueHardwareId:0
        isDebug:preferenceHelper.isDebug
        andType:&hardwareType];
    [[[systemObserverMock stub] andReturnValue:AD_TRACKING_SAFE] adTrackingSafe];
    [[[systemObserverMock stub] andReturn:BUNDLE_ID] getBundleID];
    [[[systemObserverMock stub] andReturn:APP_VERSION] getAppVersion];
    [[[systemObserverMock stub] andReturn:OS] getOS];
    [[[systemObserverMock stub] andReturn:OS_VERSION] getOSVersion];
    [[[systemObserverMock stub] andReturn:URI_SCHEME] getDefaultUriScheme];

    preferenceHelper.isDebug = [IS_DEBUG boolValue];
    preferenceHelper.linkClickIdentifier = LINK_IDENTIFIER;
    preferenceHelper.randomizedDeviceToken = nil;
    preferenceHelper.randomizedBundleToken = RANDOMIZED_BUNDLE_TOKEN;

    NSTimeInterval kOneDayAgo = -1.0*24.0*60.0*60.0;
    NSDate *installDate = [NSDate dateWithTimeIntervalSinceNow:2.0*kOneDayAgo];
    NSDate *updateDate  = [NSDate dateWithTimeIntervalSinceNow:1.0*kOneDayAgo];
    [[BNCApplication currentApplication]
        setAppOriginalInstallDate:installDate
        firstInstallDate:installDate
        lastUpdateDate:installDate];
    [preferenceHelper setPreviousAppBuildDate:updateDate];

    NSMutableDictionary *expectedParams = [NSMutableDictionary dictionaryWithDictionary:@{
        @"app_version": APP_VERSION,
        @"apple_ad_attribution_checked":@0,
        @"cd": @{
            @"mv": @"-1",
            @"pn": BUNDLE_ID
        },
        @"debug":                       IS_DEBUG,
        @"facebook_app_link_checked":   @0,
        @"randomized_bundle_token":     RANDOMIZED_BUNDLE_TOKEN,
        @"ios_bundle_id":               BUNDLE_ID,
        @"ios_team_id":                 @"R63EM248DP",
        @"link_identifier":             LINK_IDENTIFIER,
        @"uri_scheme":                  URI_SCHEME,

        @"latest_install_time":         BNCWireFormatFromDate(installDate),
        @"lastest_update_time":         BNCWireFormatFromDate(installDate),
        @"first_install_time":          BNCWireFormatFromDate(installDate),
        @"previous_update_time":        BNCWireFormatFromDate(updateDate),
        @"update":                      @0,
        @"apple_testflight":            @0
    }];
    if (!self.class.isApplication) expectedParams[@"ios_team_id"] = nil;

    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect]
        postRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
            XCTAssertEqualObjects(obj, expectedParams);
            return YES;
        }]
        url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_OPEN]
        key:[OCMArg any]
        callback:[OCMArg any]];
    
    BranchOpenRequest *request = [[BranchOpenRequest alloc] init];
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    [serverInterfaceMock verify];
}

- (void)testRequestBodyWithDeviceToken {
    NSString * const HARDWARE_ID = @"foo-hardware-id";
    NSNumber * const AD_TRACKING_SAFE = @YES;
    NSNumber * const IS_DEBUG = @YES;
    NSString * const BUNDLE_ID = @"foo-bundle-id";
    NSString * const APP_VERSION = @"foo-app-version";
    NSString * const OS = @"foo-os";
    NSString * const OS_VERSION = @"foo-os-version";
    NSString * const URI_SCHEME = @"foo-uri-scheme";
    NSString * const LINK_IDENTIFIER = @"foo-link-id";
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const RANDOMIZED_BUNDLE_TOKEN = @"foo-bundle-token";
    NSString * hardwareType = nil;

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    id systemObserverMock = OCMClassMock([BNCSystemObserver class]);
    [[[[systemObserverMock stub] ignoringNonObjectArgs] andReturn:HARDWARE_ID]
        getUniqueHardwareId:0
        isDebug:preferenceHelper.isDebug
        andType:&hardwareType];
    [[[systemObserverMock stub] andReturnValue:AD_TRACKING_SAFE] adTrackingSafe];
    [[[systemObserverMock stub] andReturn:BUNDLE_ID] getBundleID];
    [[[systemObserverMock stub] andReturn:APP_VERSION] getAppVersion];
    [[[systemObserverMock stub] andReturn:OS] getOS];
    [[[systemObserverMock stub] andReturn:OS_VERSION] getOSVersion];
    [[[systemObserverMock stub] andReturn:URI_SCHEME] getDefaultUriScheme];

    preferenceHelper.isDebug = [IS_DEBUG boolValue];
    preferenceHelper.linkClickIdentifier = LINK_IDENTIFIER;
    preferenceHelper.randomizedDeviceToken = DEVICE_TOKEN;
    preferenceHelper.randomizedBundleToken = RANDOMIZED_BUNDLE_TOKEN;

    NSTimeInterval kOneDayAgo = -1.0*24.0*60.0*60.0;
    NSDate *installDate = [NSDate dateWithTimeIntervalSinceNow:2.0*kOneDayAgo];
    NSDate *updateDate  = [NSDate dateWithTimeIntervalSinceNow:1.0*kOneDayAgo];
    [[BNCApplication currentApplication]
        setAppOriginalInstallDate:installDate
        firstInstallDate:installDate
        lastUpdateDate:installDate];
    [preferenceHelper setPreviousAppBuildDate:updateDate];

    NSMutableDictionary *expectedParams = [NSMutableDictionary dictionaryWithDictionary:@{
        @"app_version": APP_VERSION,
        @"apple_ad_attribution_checked":@0,        
        @"cd": @{
            @"mv": @"-1",
            @"pn": BUNDLE_ID
        },
        @"debug":                       IS_DEBUG,
        @"randomized_device_token":     DEVICE_TOKEN,
        @"facebook_app_link_checked":   @0,
        @"randomized_bundle_token":     RANDOMIZED_BUNDLE_TOKEN,
        @"ios_bundle_id":               BUNDLE_ID,
        @"ios_team_id":                 @"R63EM248DP",
        @"link_identifier":             LINK_IDENTIFIER,
        @"uri_scheme":                  URI_SCHEME,

        @"latest_install_time":         BNCWireFormatFromDate(installDate),
        @"lastest_update_time":         BNCWireFormatFromDate(installDate),
        @"first_install_time":          BNCWireFormatFromDate(installDate),
        @"previous_update_time":        BNCWireFormatFromDate(updateDate),
        @"update":                      @0,
        @"apple_testflight":            @0
    }];
    if (!self.class.isApplication) expectedParams[@"ios_team_id"] = nil;

    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect]
        postRequest:expectedParams
        url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_OPEN]
        key:[OCMArg any]
        callback:[OCMArg any]];
    
    BranchOpenRequest *request = [[BranchOpenRequest alloc] init];
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    [serverInterfaceMock verify];
}

- (void)testSuccessWithAllKeysAndIsReferrable {
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const SESSION_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
    NSString * const RANDOMIZED_BUNDLE_TOKEN = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_SESSION_DATA: SESSION_PARAMS,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: RANDOMIZED_BUNDLE_TOKEN
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    } isInstall:TRUE];

    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionParams, SESSION_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.installParams, SESSION_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, RANDOMIZED_BUNDLE_TOKEN);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
}

- (void)testSuccessWithAllKeysAndIsNotReferrable {
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const SESSION_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_SESSION_DATA: SESSION_PARAMS,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: IDENTITY
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionParams, SESSION_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, IDENTITY);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
}

- (void)testSuccessWithNoSessionParamsAndIsNotReferrable {
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: IDENTITY
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, IDENTITY);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
}

- (void)testSuccessWithNoSessionParamsAndIsReferrableAndAllowToBeClearIsNotSet {
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: IDENTITY
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, IDENTITY);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
}

- (void)testSuccessWithNoSessionParamsAndIsReferrableAndAllowToBeClearIsSet {
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: IDENTITY
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    } isInstall:NO];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, IDENTITY);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
    XCTAssertNil(preferenceHelper.installParams);
}

- (void)testOpenWhenReferrableAndNoInstallParamsAndNonNullData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    NSString * const OPEN_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(preferenceHelper.installParams, OPEN_PARAMS);
        
        [self safelyFulfillExpectation:expectation];
    } isInstall:TRUE];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenReferrableAndNoInstallParamsAndNullData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(preferenceHelper.installParams);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenReferrableAndNoInstallParamsAndNonLinkClickData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    NSString * const OPEN_PARAMS = @"{\"+clicked_branch_link\":0}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(preferenceHelper.installParams);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenReferrableAndInstallParams {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    NSString * const INSTALL_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
    NSString * const OPEN_PARAMS = @"{\"+clicked_branch_link\":1,\"bar\":\"foo\"}";
    
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenNotReferrable {
    //  'isReferrable' seems to be an empty concept in iOS.
    //  It is in the code but not used. -- Edward.

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    NSString * const OPEN_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssert([preferenceHelper.installParams isEqualToString:OPEN_PARAMS]);
        [self safelyFulfillExpectation:expectation];
    } isInstall:TRUE];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

@end
