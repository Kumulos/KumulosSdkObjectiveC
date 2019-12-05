//
//  KumulosNotificationService.h
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 05/12/2019.
//

#import <Foundation/Foundation.h>

@import UserNotifications;
@import UIKit;

@interface KumulosNotificationService : NSObject

/**
* Implementation of Notification Service Extension. Handles display of pictures in notifications
* @param request  from Notification Service Extension
* @param contentHandler from Notification Service Extension
*/
+ (void) didReceiveNotificationRequest:(UNNotificationRequest * _Nonnull)request withContentHandler:(void (^_Nonnull)(UNNotificationContent * _Nonnull))contentHandler API_AVAILABLE(ios(10.0));

@end
