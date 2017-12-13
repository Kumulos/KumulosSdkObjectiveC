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
#endif

#import <KSCrash/KSCrash.h>
#import <KSCrash/KSCrashInstallationStandard.h>

static NSString * const KSStatsBaseUrl = @"https://stats.kumulos.com";
static NSString * const KSPushBaseUrl = @"https://push.kumulos.com";
static NSString * const KSCrashBaseUrl = @"https://crash.kumulos.com";

@implementation KSConfig

+ (instancetype _Nullable) configWithAPIKey:(NSString* _Nonnull)APIKey andSecretKey:(NSString* _Nonnull)secretKey {
    KSConfig* config = [[KSConfig alloc] initWithAPIKey:APIKey andSecretKey:secretKey];
    return config;
}

- (instancetype _Nullable) initWithAPIKey:(NSString* _Nonnull)APIKey andSecretKey:(NSString* _Nonnull)secretKey {
    if (self = [super init]) {
        self->_apiKey = APIKey;
        self->_secretKey = secretKey;
        self->_crashReportingEnabled = NO;
    }
    return self;
}

- (instancetype _Nonnull) enableCrashReporting {
    self->_crashReportingEnabled = YES;
    return self;
}

@end

@implementation Kumulos

static Kumulos* _shared;

+ (NSString*) installId {
    @synchronized (self) {
        NSString* installId = [[NSUserDefaults standardUserDefaults] objectForKey:KUMULOS_INSTALL_ID_KEY];
        
        if (!installId) {
            installId = [[[NSUUID UUID] UUIDString] lowercaseString];
            [[NSUserDefaults standardUserDefaults] setObject:installId forKey:KUMULOS_INSTALL_ID_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        return installId;
    }
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
        
        self.sessionToken = [[KSessionTokenManager sharedManager] sessionTokenForKey:config.apiKey];
        
        [self initNetworkingHelpers];
        
#if TARGET_OS_IOS
        [self initAnalytics];
#endif
        
        [self statsSendInstallInfo];
        
        if (config.crashReportingEnabled) {
            [self initCrashReporting];
        }
    }
    return self;
}

- (instancetype _Nullable) initWithAPIKey:(NSString *)APIKey andSecretKey:(NSString *)secretKey {
    KSConfig* config = [KSConfig configWithAPIKey:APIKey andSecretKey:secretKey];
    return [self initWithConfig:config];
}

- (void) initNetworkingHelpers {
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.rpcHttpClient = [[RpcHttpClient alloc] initWithApiKey:self.apiKey andSecretKey:self.secretKey];
    self.statsHttpClient = [[AuthedJsonHttpClient alloc] initWithBaseUrl:KSStatsBaseUrl apiKey:self.apiKey andSecretKey:self.secretKey];
    self.pushHttpClient = [[AuthedJsonHttpClient alloc] initWithBaseUrl:KSPushBaseUrl apiKey:self.apiKey andSecretKey:self.secretKey];
}

#if TARGET_OS_IOS
- (void) initAnalytics {
    self.analyticsHelper = [[AnalyticsHelper alloc] initWithKumulos:self];
}
#endif

- (void) initCrashReporting {
    NSString* url = [NSString stringWithFormat:@"%@/v1/track/%@/kscrash/%@", KSCrashBaseUrl, self.apiKey, Kumulos.installId];
    KSCrashInstallationStandard* installation = [KSCrashInstallationStandard sharedInstance];
    installation.url = [NSURL URLWithString:url];
    
    [installation install];
    
    [installation sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        // noop
    }];
}

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
    
    [self.statsHttpClient invalidateSessionCancelingTasks:YES];
    self.statsHttpClient = nil;
    
    [self.pushHttpClient invalidateSessionCancelingTasks:YES];
    self.pushHttpClient = nil;
}

@end
