//
//  KSPendingNotificationHelper.h
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 10/03/2021.
//

#import "KSPendingNotification.h"

#ifndef KSPendingNotificationHelper_h
#define KSPendingNotificationHelper_h

@interface KSPendingNotificationHelper : NSObject

+ (void)remove:(NSNumber*)notificationId;
+ (void)removeByIdentifier:(NSString*)identifier;
+ (NSMutableArray<KSPendingNotification*>*)readAll;
+ (void)add:(KSPendingNotification*) notification;

@end

#endif /* KSPendingNotificationHelper_h */
