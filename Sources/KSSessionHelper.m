//
//  KSSessionHelper.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import <Foundation/Foundation.h>
#import "KSSessionHelper.h"
#import "Kumulos+Protected.h"
#import "KumulosEvents.h"

@interface KSSessionHelper ()

@property (atomic) BOOL startNewSession;
@property (atomic) NSDate* becameInactiveAt;
@property (atomic) NSTimer* sessionIdleTimer;
@property (atomic) UIBackgroundTaskIdentifier bgTask;
@property (atomic) NSUInteger sessionIdleTimeout;
@property (nonatomic) KSAnalyticsHelper* _Nonnull analyticsHelper;

@end


@implementation KSSessionHelper


- (instancetype) initWithSessionIdleTimeout:(NSUInteger)timeout analyticsHelper:(KSAnalyticsHelper*) analyticsHelper {
    if (self = [super init]) {
        self.startNewSession = YES;
        self.sessionIdleTimer = nil;
        self.bgTask = UIBackgroundTaskInvalid;
        self.sessionIdleTimeout = timeout;
        self.analyticsHelper = analyticsHelper;
        
        [self registerListeners];
    }
    
    return self;
}

- (void) registerListeners {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(appBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(appBecameInactive) name:UIApplicationWillResignActiveNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(appBecameBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(appWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
}


- (void) appBecameActive {
    if (self.startNewSession) {
        [self.analyticsHelper trackEvent:KumulosEventForeground withProperties:nil];
        self.startNewSession = NO;
        return;
    }
    
    if (self.sessionIdleTimer) {
        [self.sessionIdleTimer invalidate];
        self.sessionIdleTimer = nil;
    }

    [self maybeEndBgTask];
}

- (void) appBecameInactive {
    self.becameInactiveAt = [NSDate date];
    
    self.sessionIdleTimer = [NSTimer scheduledTimerWithTimeInterval:self.sessionIdleTimeout target:self selector:@selector(sessionDidEnd) userInfo:nil repeats:NO];
}

- (void) appBecameBackground {
    self.bgTask = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"sync" expirationHandler:^{
        [self maybeEndBgTask];
    }];

    if (self.becameInactiveAt == nil) {
        self.becameInactiveAt = [NSDate date];
    }
}

- (void) appWillTerminate {
    if (self.becameInactiveAt == nil) {
        self.becameInactiveAt = [NSDate date];
    }

    if (self.sessionIdleTimer) {
        [self.sessionIdleTimer invalidate];
        [self sessionDidEnd];
    }
}

- (void) sessionDidEnd {
    if (self.becameInactiveAt == nil) {
        return;
    }

    self.startNewSession = YES;
    self.sessionIdleTimer = nil;

    dispatch_semaphore_t __block syncBarrier = dispatch_semaphore_create(0);
    
    [self.analyticsHelper trackEvent:KumulosEventBackground atTime:self.becameInactiveAt withProperties:nil flushingImmediately:YES onSyncComplete:^(NSError * _Nullable error){
        self.becameInactiveAt = nil;
        
        [self maybeEndBgTask];

        dispatch_semaphore_signal(syncBarrier);
    }];

    dispatch_semaphore_wait(syncBarrier, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
}

- (void) maybeEndBgTask {
    if (self.bgTask == UIBackgroundTaskInvalid) {
        return;
    }

    UIBackgroundTaskIdentifier taskId = self.bgTask;
    self.bgTask = UIBackgroundTaskInvalid;
    [UIApplication.sharedApplication endBackgroundTask:taskId];
}

@end
