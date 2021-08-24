//
//  Kumulos+Protected.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import "Kumulos.h"
#import "Shared/Http/KSHttpClient.h"
#import "Shared/KumulosHelper.h"
#import "Shared/KumulosErrors.h"

#if TARGET_OS_IOS
#import "Shared/KSAnalyticsHelper.h"
#import "Shared/KSKeyValPersistenceHelper.h"
#import "Shared/KumulosUserDefaultsKeys.h"
#import "Shared/KSPendingNotification.h"
#import "Shared/KSPendingNotificationHelper.h"
#import "Shared/KSMediaHelper.h"
#import "KSSessionHelper.h"
#import "InApp/KSInAppHelper.h"
#import "DeepLinkHelper.h"
#import "KSDeepLinkFingerprinter.h"

@import UserNotifications;
#endif

@interface Kumulos ()

@property (nonatomic) NSString* _Nonnull apiKey;
@property (nonatomic) NSString* _Nonnull secretKey;

@property (nonatomic) NSOperationQueue* _Nullable operationQueue;

@property (nonatomic) KSHttpClient* _Nullable rpcHttpClient;
@property (nonatomic) KSHttpClient* _Nullable pushHttpClient;
@property (nonatomic) KSHttpClient* _Nullable crmHttpClient;

#if TARGET_OS_IOS
@property (nonatomic) KSAnalyticsHelper* _Nullable analyticsHelper;
@property (nonatomic) KSSessionHelper* _Nullable sessionHelper;
@property (nonatomic) KSInAppHelper* _Nullable inAppHelper;
@property (nonatomic) KSDeepLinkHelper* _Nullable deepLinkHelper;
@property (nonatomic) NSObject<UNUserNotificationCenterDelegate>* _Nullable notificationCenterDelegate API_AVAILABLE(ios(10.0));
#else
@property (nonatomic) KSHttpClient* _Nullable statsHttpClient;
#endif

@end

