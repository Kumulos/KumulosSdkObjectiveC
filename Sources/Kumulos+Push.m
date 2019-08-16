//
//  Kumulos+Push.m
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

@import UserNotifications;
#import <objc/runtime.h>
#import "Kumulos+Push.h"
#import "Kumulos+Protected.h"
#import "MobileProvision.h"
#import "KumulosEvents.h"
#import "KSUserNotificationCenterDelegate.h"

static NSInteger const KSPushTokenTypeProduction = 1;
static NSInteger const KSPushDeviceType = 1;

static IMP ks_existingPushRegisterDelegate = NULL;
static IMP ks_existingPushRegisterFailDelegate = NULL;
static IMP ks_existingPushReceiveDelegate = NULL;

typedef void (^KSCompletionHandler)(UIBackgroundFetchResult);
void kumulos_applicationDidRegisterForRemoteNotifications(id self, SEL _cmd, UIApplication* application, NSData* deviceToken);
void kumulos_applicationdidFailToRegisterForRemoteNotifications(id self, SEL _cmd, UIApplication* application, NSError* error);
void kumulos_applicationDidReceiveRemoteNotificationFetchCompletionHandler(id self, SEL _cmd, UIApplication* applicaiton, NSDictionary* notification, KSCompletionHandler completionHandler);

@interface Kumulos (PushPrivate)

@property (nonatomic) KSUserNotificationCenterDelegate* notificationCenterDelegate;

@end

@implementation Kumulos (Push)

- (void) pushInit {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = UIApplication.sharedApplication.delegate.class;

        // Did register push delegate
        SEL didRegisterSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        const char *regType = [[NSString stringWithFormat:@"%s%s%s%s%s", @encode(void), @encode(id), @encode(SEL), @encode(UIApplication*), @encode(NSData*)] UTF8String];

        ks_existingPushRegisterDelegate = class_replaceMethod(class, didRegisterSelector, (IMP)kumulos_applicationDidRegisterForRemoteNotifications, regType);

        // Failed to register handler
        SEL didFailToRegisterSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        const char *regFailType = [[NSString stringWithFormat:@"%s%s%s%s%s", @encode(void), @encode(id), @encode(SEL), @encode(UIApplication*), @encode(NSError*)] UTF8String];

        ks_existingPushRegisterFailDelegate = class_replaceMethod(class, didFailToRegisterSelector, (IMP)kumulos_applicationdidFailToRegisterForRemoteNotifications, regFailType);

        // iOS9 did receive remote delegate
        // iOS9+ content-available handler
        SEL didReceiveSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
        const char *recType = [[NSString stringWithFormat:@"%s%s%s%s%s%s", @encode(void), @encode(id), @encode(SEL), @encode(UIApplication*), @encode(NSDictionary*), @encode(KSCompletionHandler)] UTF8String];
        ks_existingPushReceiveDelegate = class_replaceMethod(class, didReceiveSelector, (IMP) kumulos_applicationDidReceiveRemoteNotificationFetchCompletionHandler, recType);

        if (@available(iOS 10, *)) {
            self.notificationCenterDelegate = [[KSUserNotificationCenterDelegate alloc] initWithKumulos:self];
            [UNUserNotificationCenter.currentNotificationCenter setDelegate:self.notificationCenterDelegate];
        }
    });
}

- (void) pushRequestDeviceToken {
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter* notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
        UNAuthorizationOptions options = (UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge);
        [notificationCenter requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError* error) {
            if (!granted || error != nil) {
                return;
            }

            [UIApplication.sharedApplication performSelectorOnMainThread:@selector(registerForRemoteNotifications) withObject:nil waitUntilDone:YES];
        }];
    } else {
        [self performSelectorOnMainThread:@selector(legacyRegisterForToken) withObject:nil waitUntilDone:YES];
    }
}

- (void) legacyRegisterForToken {
    UIUserNotificationType types = (UIUserNotificationType) (UIUserNotificationTypeBadge |
                                                             UIUserNotificationTypeSound | UIUserNotificationTypeAlert);
    
    UIUserNotificationSettings *settings =
    [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void) pushRegisterWithDeviceToken:(NSData*)deviceToken {
    NSString* token = [self pushTokenFromData:deviceToken];
    
    NSDictionary* info = @{@"token": token,
                           @"type": @(KSPushDeviceType),
                           @"iosTokenType": [self pushGetTokenType]};
    
    [self.analyticsHelper trackEvent:KumulosEventPushRegistered withProperties:info flushingImmediately:YES];
}

- (void) pushUnregister {
    [self.analyticsHelper trackEvent:KumulosEventDeviceUnsubscribed withProperties:nil flushingImmediately:YES];
}

- (void) pushTrackOpenFromNotification:(NSDictionary* _Nullable)userInfo {
    if (nil == userInfo) {
        return;
    }
    
    NSDictionary* notification = userInfo;
    NSDictionary* custom = notification[@"custom"];
    
    if (nil == custom || !custom[@"i"]) {
        return;
    }
    
    NSDictionary* params = @{@"id": custom[@"i"]};
    
    [self.analyticsHelper trackEvent:KumulosEventPushOpened withProperties:params];
}

- (NSNumber*) pushGetTokenType {
    UIApplicationReleaseMode releaseMode = [MobileProvision releaseMode];
    
    if (releaseMode == UIApplicationReleaseAdHoc
        || releaseMode == UIApplicationReleaseDev
        || releaseMode == UIApplicationReleaseWildcard) {
        return @(releaseMode + 1);
    }
    
    return @(KSPushTokenTypeProduction);
}

- (NSString*) pushTokenFromData:(NSData*) deviceToken {
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];
    
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    
    return [token copy];
}

@end

#pragma mark - Swizzled behaviour hooks

void kumulos_applicationDidRegisterForRemoteNotifications(id self, SEL _cmd, UIApplication* application, NSData* deviceToken) {
    if (ks_existingPushRegisterDelegate) {
        ((void(*)(id,SEL,UIApplication*,NSData*))ks_existingPushRegisterDelegate)(self, _cmd, application, deviceToken);
    }

    [Kumulos.shared pushRegisterWithDeviceToken:deviceToken];
}

void kumulos_applicationdidFailToRegisterForRemoteNotifications(id self, SEL _cmd, UIApplication* application, NSError* error) {
    if (ks_existingPushReceiveDelegate) {
        ((void(*)(id,SEL,UIApplication*,NSError*))ks_existingPushRegisterFailDelegate)(self, _cmd, application, error);
    }

    NSLog(@"Failed to register for remote notifications: %@", error);
}

// iOS9 handler for push notifications
// iOS9+ handler for background data pushes (content-available)
void kumulos_applicationDidReceiveRemoteNotificationFetchCompletionHandler(id self, SEL _cmd, UIApplication* application, NSDictionary* userInfo, KSCompletionHandler completionHandler) {
    UIBackgroundFetchResult __block fetchResult = UIBackgroundFetchResultNoData;

    if (ks_existingPushReceiveDelegate) {
        ((void(*)(id,SEL,UIApplication*,NSDictionary*,KSCompletionHandler))ks_existingPushReceiveDelegate)(self, _cmd, application, userInfo, ^(UIBackgroundFetchResult result) {
            fetchResult = result;
        });
    }

    if (UIApplication.sharedApplication.applicationState == UIApplicationStateInactive) {
        if (@available(iOS 10, *)) {
            // Noop (tap handler in delegate will deal with opening the URL
        } else {
            [Kumulos.shared pushTrackOpenFromNotification:userInfo];

            // Handle opening URLs on notification taps
            NSURL* url = [NSURL URLWithString:userInfo[@"custom"][@"u"]];
            if (url) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication.sharedApplication openURL:url];
                });
            }
        }
    }

    completionHandler(fetchResult);
}
