//
//  SessionHelper.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import <Foundation/Foundation.h>
#import "SessionHelper.h"
#import "Kumulos+Protected.h"
#import "KumulosEvents.h"

@interface SessionHelper ()

@property (atomic) BOOL startNewSession;
@property (atomic) NSDate* becameInactiveAt;
@property (atomic) NSTimer* sessionIdleTimer;
@property (atomic) UIBackgroundTaskIdentifier bgTask;
@property (atomic) NSUInteger sessionIdleTimeout;
@property (nonatomic) AnalyticsHelper* _Nonnull analyticsHelper;

@end


@implementation SessionHelper


- (instancetype) initWithSessionIdleTimeout:(NSUInteger)timeout analyticsHelper:(AnalyticsHelper*) analyticsHelper {
    if (self = [super init]) {
        self.startNewSession = YES;
        self.sessionIdleTimer = nil;
        self.bgTask = UIBackgroundTaskInvalid;
        self.sessionIdleTimeout = timeout;
        self.analyticsHelper = analyticsHelper;
    }
    
    return self;
}

- (void) initialize {
    [self registerListeners];
}


- (void) registerListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameInactive) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
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
    
    if (self.bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
}

- (void) appBecameInactive {
    self.becameInactiveAt = [NSDate date];
    
    self.sessionIdleTimer = [NSTimer scheduledTimerWithTimeInterval:self.sessionIdleTimeout target:self selector:@selector(sessionDidEnd) userInfo:nil repeats:NO];
}

- (void) appBecameBackground {
    self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"sync" expirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void) appWillTerminate {
    if (self.sessionIdleTimer) {
        [self.sessionIdleTimer invalidate];
        [self sessionDidEnd];
    }
}

- (void) sessionDidEnd {
    self.startNewSession = YES;
    self.sessionIdleTimer = nil;
    
    [self.analyticsHelper trackEvent:KumulosEventBackground atTime:self.becameInactiveAt withProperties:nil flushingImmediately:YES onSyncComplete:^(NSError * _Nullable error){
        self.becameInactiveAt = nil;
        
        if (self.bgTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
            self.bgTask = UIBackgroundTaskInvalid;
        }
        
    }];
    
}

@end
