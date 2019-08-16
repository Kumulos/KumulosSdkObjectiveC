//
//  KSUserNotificationCenterDelegate.h
//  KumulosSDK
//

#import <Foundation/Foundation.h>
@import UserNotifications;
#import "Kumulos.h"

@interface KSUserNotificationCenterDelegate : NSObject <UNUserNotificationCenterDelegate>
- (instancetype)initWithKumulos:(Kumulos*)kumulos;
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler API_AVAILABLE(ios(10));
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10));
@end
