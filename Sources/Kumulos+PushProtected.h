//
//  Kumulos+PushProtected.h
//  KumulosSDK
//

#import "Kumulos+Push.h"
#import "KSUserNotificationCenterDelegate.h"

@interface Kumulos (PushProtected)

- (void) pushInit;
- (void) pushHandleOpenWithUserInfo:(NSDictionary* _Nullable)userInfo;

@end
