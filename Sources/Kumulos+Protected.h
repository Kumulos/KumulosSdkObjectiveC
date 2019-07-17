//
//  Kumulos+Protected.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import "Kumulos.h"
#import "Http/KSHttpClient.h"

#if TARGET_OS_IOS
#import "AnalyticsHelper.h"
#import "InApp/KSInAppHelper.h"
#endif

#define KUMULOS_INSTALL_ID_KEY @"KumulosUUID"
#define KUMULOS_USER_ID_KEY @"KumulosCurrentUserID"

@interface Kumulos ()

@property (nonatomic) NSString* apiKey;
@property (nonatomic) NSString* secretKey;

@property (nonatomic) NSOperationQueue* operationQueue;

@property (nonatomic) KSHttpClient* rpcHttpClient;
@property (nonatomic) KSHttpClient* pushHttpClient;

#if TARGET_OS_IOS
@property (nonatomic) AnalyticsHelper* analyticsHelper;
@property (nonatomic) KSHttpClient* eventsHttpClient;
@property (nonatomic) KSInAppHelper* inAppHelper;
#else
@property (nonatomic) KSHttpClient* statsHttpClient;
#endif

@end
