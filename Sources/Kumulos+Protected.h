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
@import UserNotifications;
#endif

#define KUMULOS_INSTALL_ID_KEY @"KumulosUUID"
#define KUMULOS_USER_ID_KEY @"KumulosCurrentUserID"

@interface Kumulos ()

@property (nonatomic) NSString* _Nonnull apiKey;
@property (nonatomic) NSString* _Nonnull secretKey;

@property (nonatomic) NSOperationQueue* _Nullable operationQueue;

@property (nonatomic) KSHttpClient* _Nullable rpcHttpClient;
@property (nonatomic) KSHttpClient* _Nullable pushHttpClient;

#if TARGET_OS_IOS
@property (nonatomic) AnalyticsHelper* _Nullable analyticsHelper;
@property (nonatomic) KSHttpClient* _Nullable eventsHttpClient;
@property (nonatomic) KSInAppHelper* _Nullable inAppHelper;
@property (nonatomic) NSObject<UNUserNotificationCenterDelegate>* _Nullable notificationCenterDelegate API_AVAILABLE(ios(10.0));
#else
@property (nonatomic) KSHttpClient* _Nullable statsHttpClient;
#endif

@end

