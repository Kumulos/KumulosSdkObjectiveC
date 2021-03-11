//
//  Kumulos+PushProtected.h
//  KumulosSDK
//

#import "Kumulos+Push.h"
#import "KSUserNotificationCenterDelegate.h"

@interface Kumulos (PushProtected)

- (void) pushInit;
- (BOOL) pushHandleOpenWithUserInfo:(NSDictionary* _Nullable)userInfo;
- (BOOL) pushHandleOpenWithUserInfo:(NSDictionary* _Nonnull)userInfo withNotificationResponse: (UNNotificationResponse* _Nonnull)response API_AVAILABLE(ios(10.0));
- (BOOL) pushHandleDismissed:(NSDictionary*)userInfo withNotificationResponse: (UNNotificationResponse*)response;
- (void) maybeTrackPushDismissedEvents;


@end
