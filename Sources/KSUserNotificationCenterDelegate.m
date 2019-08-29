//
//  KSUserNotificationCenterDelegate.m
//  KumulosSDK
//

#import "KSUserNotificationCenterDelegate.h"
#import "Kumulos+PushProtected.h"

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
    if (self.kumulos.config.pushReceivedInForegroundHandler) {
        KSPushNotification* push = [KSPushNotification fromUserInfo:notification.request.content.userInfo];
        self.kumulos.config.pushReceivedInForegroundHandler(push, completionHandler);
    } else {
        completionHandler(UNNotificationPresentationOptionAlert);
    }
}

// iOS10+ handler for when a user taps a notification
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    if ([response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
        completionHandler();
        return;
    }

    NSDictionary* userInfo = response.notification.request.content.userInfo;
    [self.kumulos pushHandleOpenWithUserInfo:userInfo];

    completionHandler();
}

@end
