//
//  KSUserNotificationCenterDelegate.m
//  KumulosSDK
//

#import "KSUserNotificationCenterDelegate.h"

@interface KSUserNotificationCenterDelegate ()

@property (nonatomic) Kumulos* kumulos;

@end

@implementation KSUserNotificationCenterDelegate

- (instancetype)initWithKumulos:(Kumulos *)kumulos {
    if (self = [super init]) {
        self.kumulos = kumulos;
    }

    return self;
}

// Called on iOS10+ when your app is in the foreground to allow customizing the display of the notification
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert);
}

// iOS10+ handler for when a user taps a notification
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSDictionary* userInfo = response.notification.request.content.userInfo;
    [self.kumulos pushTrackOpenFromNotification:userInfo];

    // Handle URL pushes
    NSURL* url = [NSURL URLWithString:userInfo[@"custom"][@"u"]];
    if (url) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {
            /* noop */
        }];
    }

    completionHandler();
}

@end
