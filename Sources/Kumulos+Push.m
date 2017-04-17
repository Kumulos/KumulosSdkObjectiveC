//
//  Kumulos+Push.m
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

@import UserNotifications;
#import "Kumulos+Push.h"
#import "Kumulos+Protected.h"
#import "MobileProvision.h"

static NSInteger const KSPushTokenTypeProduction = 1;
static NSInteger const KSPushDeviceType = 1;

@implementation Kumulos (Push)

- (void) pushRequestDeviceToken {
    NSOperatingSystemVersion v10 = (NSOperatingSystemVersion){10,0,0};
    
    if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:v10]) {
        [self legacyRegisterForToken];
        return;
    }
    
    UNUserNotificationCenter* notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions options = (UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge);
    [notificationCenter requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError* error) {
        if (!granted || error != nil) {
            return;
        }
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }];
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
    
    NSString* path = [NSString stringWithFormat:@"/v1/app-installs/%@/push-token", [Kumulos installId]];
    
    [self.pushHttpClient PUT:path parameters:info success:^(NSURLSessionDataTask* task, id response) {
#ifdef DEBUG
        NSLog(@"Kumulos: Registed for push notifications");
#endif
    } failure:^(NSURLSessionDataTask* task, NSError* error) {
#ifdef DEBUG
        NSLog(@"Kumulos: Failed to register for push notifications");
#endif
    }];
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
    NSString* path = [NSString stringWithFormat:@"/v1/app-installs/%@/opens", [Kumulos installId]];
    
    [self.pushHttpClient POST:path parameters:params progress:nil success:^(NSURLSessionDataTask* task, id response) {
        // Noop
    } failure:^(NSURLSessionDataTask* task, NSError* error) {
        // Noop
    }];
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
