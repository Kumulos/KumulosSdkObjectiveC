//
//  Kumulos+Protected.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import "Kumulos.h"
#import "Shared/Http/KSHttpClient.h"

#if TARGET_OS_IOS
#import "Shared/AnalyticsHelper.h"
#import "Shared/KumulosHelper.h"
#import "Shared/KSKeyValPersistenceHelper.h"
#import "Shared/KumulosUserDefaultsKeys.h"
#import "SessionHelper.h"
#import "InApp/KSInAppHelper.h"
@import UserNotifications;
#endif

@interface Kumulos ()

@property (nonatomic) NSString* _Nonnull apiKey;
@property (nonatomic) NSString* _Nonnull secretKey;

@property (nonatomic) NSOperationQueue* _Nullable operationQueue;

@property (nonatomic) KSHttpClient* _Nullable rpcHttpClient;
@property (nonatomic) KSHttpClient* _Nullable pushHttpClient;

#if TARGET_OS_IOS
@property (nonatomic) AnalyticsHelper* _Nullable analyticsHelper;
@property (nonatomic) SessionHelper* _Nullable sessionHelper;
@property (nonatomic) KSInAppHelper* _Nullable inAppHelper;
@property (nonatomic) NSObject<UNUserNotificationCenterDelegate>* _Nullable notificationCenterDelegate API_AVAILABLE(ios(10.0));
#else
@property (nonatomic) KSHttpClient* _Nullable statsHttpClient;
#endif

@end

