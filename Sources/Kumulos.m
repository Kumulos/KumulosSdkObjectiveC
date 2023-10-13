//
//  Kumulos.m
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import "Kumulos.h"
#import "KSAPIOperation.h"
#import "Kumulos+Protected.h"
#import "Kumulos+Stats.h"
#import "KSessionTokenManager.h"

#if TARGET_OS_IOS
#import "Kumulos+Push.h"
#import "Kumulos+PushProtected.h"
#endif

static NSString * const KSBackendBaseUrl = @"https://api.kumulos.com";
static NSString * const KSStatsBaseUrl = @"https://stats.kumulos.com";
static NSString * const KSPushBaseUrl = @"https://push.kumulos.com";
static NSString * const KSCrmCoreBaseUrl = @"https://crm.kumulos.com";

@implementation KSConfig

+ (instancetype _Nullable) configWithAPIKey:(NSString* _Nonnull)APIKey andSecretKey:(NSString* _Nonnull)secretKey {
    KSConfig* config = [[KSConfig alloc] initWithAPIKey:APIKey andSecretKey:secretKey];
    return config;
}

- (instancetype _Nullable) initWithAPIKey:(NSString* _Nonnull)APIKey andSecretKey:(NSString* _Nonnull)secretKey {
    if (self = [super init]) {
        self->_apiKey = APIKey;
        self->_secretKey = secretKey;
        self->_sessionIdleTimeoutSeconds = 23;
        self->_runtimeInfo = nil;
        self->_sdkInfo = nil;
        self->_targetType = TargetTypeNotOverridden;
        self->_inAppConsentStrategy = KSInAppConsentStrategyNotEnabled;
        self->_inAppDeepLinkHandler = nil;
        self->_pushOpenedHandler = nil;
        self->_pushReceivedInForegroundHandler = nil;
        self->_deepLinkHandler = nil;
        self->_deepLinkCname = nil;
        
        #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR || TARGET_OS_IOS
        if (@available(iOS 10, *)) {
            self->_foregroundPushPresentationOptions = UNNotificationPresentationOptionAlert;
        }
        #endif
    }
    return self;
}

- (instancetype _Nonnull) enableDeepLinking:(NSString* _Nonnull)cname deepLinkHandler:(KSDeepLinkHandlerBlock)deepLinkHandler {
    self->_deepLinkHandler = deepLinkHandler;
    self->_deepLinkCname = [NSURL URLWithString:cname];
    
    return self;
}

- (instancetype _Nonnull) enableDeepLinking:(KSDeepLinkHandlerBlock)deepLinkHandler {
    self->_deepLinkHandler = deepLinkHandler;
    self->_deepLinkCname = nil;
    
    return self;
}

- (instancetype _Nonnull) enableInAppMessaging:(KSInAppConsentStrategy)consentStrategy {
    self->_inAppConsentStrategy = consentStrategy;
    return self;
}

- (instancetype)setInAppDeepLinkHandler:(KSInAppDeepLinkHandlerBlock)deepLinkHandler {
    self->_inAppDeepLinkHandler = deepLinkHandler;
    return self;
}

- (instancetype)setPushOpenedHandler:(KSPushOpenedHandlerBlock)notificationHandler {
    self->_pushOpenedHandler = notificationHandler;
    return self;
}

- (instancetype)setForegroundPushPresentationOptions:(UNNotificationPresentationOptions)notificationPresentationOptions API_AVAILABLE(ios(10.0),macos(10.14)) {
    self->_foregroundPushPresentationOptions = notificationPresentationOptions;
    return self;
}

- (instancetype)setPushReceivedInForegroundHandler:(KSPushReceivedInForegroundHandlerBlock)receivedHandler API_AVAILABLE(macos(10.14)){
    self->_pushReceivedInForegroundHandler = receivedHandler;
    return self;
}

- (instancetype _Nonnull) setSessionIdleTimeout:(NSUInteger)timeoutSeconds {
    self->_sessionIdleTimeoutSeconds = timeoutSeconds;
    return self;
}

- (instancetype _Nonnull) setRuntimeInfo:(NSDictionary *)info {
    self->_runtimeInfo = info;
    return self;
}

- (instancetype _Nonnull) setSdkInfo:(NSDictionary *)info {
    self->_sdkInfo = info;
    return self;
}

- (instancetype)setTargetType:(KSTargetType)type {
    self->_targetType = type;
    return self;
}

@end

@implementation Kumulos

static Kumulos* _shared;

+ (NSString*) installId {
    return KumulosHelper.installId;
}

+ (instancetype _Nullable) initializeWithConfig:(KSConfig *)config {
    _shared = [[Kumulos alloc] initWithConfig:config];
    return _shared;
}

+ (instancetype _Nullable) shared {
    return _shared;
}

- (instancetype _Nullable) initWithConfig:(KSConfig *)config {
    if (self = [super init]) {
        self.apiKey = config.apiKey;
        self.secretKey = config.secretKey;
        self.config = config;
        
#if TARGET_OS_IOS
        [KSKeyValPersistenceHelper maybeMigrateUserDefaultsToAppGroups];
        [KSKeyValPersistenceHelper setObject:config.apiKey forKey:KSPrefsKeyApiKey];
        [KSKeyValPersistenceHelper setObject:config.secretKey forKey:KSPrefsKeySecretKey];
        
        [self initAnalytics];
        [self initSessions];
        [self initInApp];
        [self pushInit];
        
        if (config.deepLinkHandler != nil){
            self.deepLinkHelper = [[KSDeepLinkHelper alloc] init:config];
            
            [self.deepLinkHelper checkForNonContinuationLinkMatch];
        }
        
        [[UIApplication sharedApplication] addObserver:self forKeyPath:@"applicationIconBadgeNumber" options:NSKeyValueObservingOptionNew context:nil];
#endif
        
        self.sessionToken = [[KSessionTokenManager sharedManager] sessionTokenForKey:config.apiKey];
        
        [self initNetworkingHelpers];
        
        [self statsSendInstallInfo];
    }
    return self;
}

#if TARGET_OS_IOS
- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    
    if ([keyPath isEqualToString:@"applicationIconBadgeNumber"]) {
        [KSKeyValPersistenceHelper setObject:change[@"new"] forKey: KSPrefsKeyBadgeCount];
    }
}
#endif

- (instancetype _Nullable) initWithAPIKey:(NSString *)APIKey andSecretKey:(NSString *)secretKey {
    KSConfig* config = [KSConfig configWithAPIKey:APIKey andSecretKey:secretKey];
    return [self initWithConfig:config];
}

- (void) initNetworkingHelpers {
    self.operationQueue = [[NSOperationQueue alloc] init];
    
    self.rpcHttpClient = [[KSHttpClient alloc] initWithBaseUrl:KSBackendBaseUrl requestBodyFormat:KSHttpDataFormatWwwUrlEncoded responseBodyFormat:KSHttpDataFormatPList];
    [self.rpcHttpClient setBasicAuthWithUser:self.config.apiKey andPassword:self.config.secretKey];
    
    self.pushHttpClient = [[KSHttpClient alloc] initWithBaseUrl:KSPushBaseUrl requestBodyFormat:KSHttpDataFormatJson responseBodyFormat:KSHttpDataFormatJson];
    [self.pushHttpClient setBasicAuthWithUser:self.config.apiKey andPassword:self.config.secretKey];
    
    self.crmHttpClient = [[KSHttpClient alloc] initWithBaseUrl:KSCrmCoreBaseUrl requestBodyFormat:KSHttpDataFormatJson responseBodyFormat:KSHttpDataFormatJson];
    [self.crmHttpClient setBasicAuthWithUser:self.config.apiKey andPassword:self.config.secretKey];
    
#if TARGET_OS_IOS

#else
    self.statsHttpClient = [[KSHttpClient alloc] initWithBaseUrl:KSStatsBaseUrl requestBodyFormat:KSHttpDataFormatJson responseBodyFormat:KSHttpDataFormatJson];
    [self.statsHttpClient setBasicAuthWithUser:self.config.apiKey andPassword:self.config.secretKey];
#endif
}

#if TARGET_OS_IOS
- (void) initSessions {
    self.sessionHelper = [[KSSessionHelper alloc] initWithSessionIdleTimeout: self.config.sessionIdleTimeoutSeconds analyticsHelper:self.analyticsHelper];
}

- (void) initAnalytics {
    self.analyticsHelper = [[KSAnalyticsHelper alloc] initWithApiKey:self.apiKey withSecretKey:self.secretKey];
}
- (void) initInApp {
    self.inAppHelper = [[KSInAppHelper alloc] initWithKumulos:self];
}
#endif

- (KSAPIOperation*) callMethod:(NSString*)method withSuccess:(KSAPIOperationSuccessBlock)success andFailure:(KSAPIOperationFailureBlock)failure {
    return [self callMethod:method withParams:nil success:success andFailure:failure];
}

- (KSAPIOperation*) callMethod:(NSString*)method withParams:(NSDictionary*)params success:(KSAPIOperationSuccessBlock)success andFailure:(KSAPIOperationFailureBlock)failure {
    return [self callMethod:method withParams:params success:success failure:failure andDelegate:nil];
}

- (KSAPIOperation*) callMethod:(NSString*)method withDelegate:(id<KSAPIOperationDelegate> _Nullable)delegate {
    return [self callMethod:method withParams:nil success:nil failure:nil andDelegate:delegate];
}

- (KSAPIOperation*) callMethod:(NSString*)method withParams:(NSDictionary*)params andDelegate:(id<KSAPIOperationDelegate> _Nullable)delegate {
    return [self callMethod:method withParams:params success:nil failure:nil andDelegate:delegate];
}

- (KSAPIOperation*) callMethod:(NSString*)method withParams:(NSDictionary*)params success:(KSAPIOperationSuccessBlock)success failure:(KSAPIOperationFailureBlock)failure andDelegate:(id <KSAPIOperationDelegate>) delegate {
    KSAPIOperation* operation = [[KSAPIOperation alloc] initWithKumulos:self method:method params:params success:success failure:failure andDelegate:delegate];
    
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (void) dealloc {
    [self.operationQueue cancelAllOperations];
    self.operationQueue = nil;
    
    [self.rpcHttpClient invalidateSessionCancelingTasks:YES];
    self.rpcHttpClient = nil;
    
#if TARGET_OS_IOS
#else
    [self.statsHttpClient invalidateSessionCancelingTasks:NO];
    self.statsHttpClient = nil;
#endif
    
    [self.pushHttpClient invalidateSessionCancelingTasks:YES];
    self.pushHttpClient = nil;
    
    [self.crmHttpClient invalidateSessionCancelingTasks:YES];
    self.crmHttpClient = nil;
}

@end
