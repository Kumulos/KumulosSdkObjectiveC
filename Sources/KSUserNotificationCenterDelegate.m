//
//  KSUserNotificationCenterDelegate.m
//  KumulosSDK
//

#import "KSUserNotificationCenterDelegate.h"
#import "Kumulos+PushProtected.h"

API_AVAILABLE(ios(10.0))
@interface KSUserNotificationCenterDelegate ()

@property (nonatomic) Kumulos* kumulos;
@property (nonatomic,weak) id <UNUserNotificationCenterDelegate> existingDelegate;

@end

API_AVAILABLE(ios(10.0))
@implementation KSUserNotificationCenterDelegate

- (instancetype)initWithKumulos:(Kumulos *)kumulos {
    if (self = [super init]) {
        self.kumulos = kumulos;

        if (UNUserNotificationCenter.currentNotificationCenter.delegate) {
            self.existingDelegate = UNUserNotificationCenter.currentNotificationCenter.delegate;
        }
    }

    return self;
}

// Called on iOS10+ when your app is in the foreground to allow customizing the display of the notification
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSDictionary* userInfo = notification.request.content.userInfo;
    KSPushNotification* push = [KSPushNotification fromUserInfo:userInfo];

    if (!push || !push.id) {
        [self chainCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
        return;
    }

    if (self.kumulos.config.pushReceivedInForegroundHandler) {
        KSPushNotification* push = [KSPushNotification fromUserInfo:notification.request.content.userInfo];
        self.kumulos.config.pushReceivedInForegroundHandler(push);
    }

    completionHandler(self.kumulos.config.foregroundPushPresentationOptions);
}

// iOS10+ handler for when a user taps a notification
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSDictionary* userInfo = response.notification.request.content.userInfo;

    if (!userInfo || !userInfo[@"aps"]) {
        [self chainCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
        return;
    }

    if ([response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
        completionHandler();
        return;
    }

    BOOL handled = [self.kumulos pushHandleOpenWithUserInfo:userInfo];

    if (!handled) {
        [self chainCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
        return;
    }

    completionHandler();
}

- (void) chainCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    if (self.existingDelegate && [self.existingDelegate respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)]) {
        [self.existingDelegate userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
        return;
    }

    completionHandler(UNNotificationPresentationOptionAlert);
}

- (void) chainCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    if (self.existingDelegate && [self.existingDelegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
        [self.existingDelegate userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
        return;
    }

    completionHandler();
}

@end
