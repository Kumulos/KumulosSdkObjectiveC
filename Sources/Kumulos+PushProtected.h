//
//  Kumulos+PushProtected.h
//  KumulosSDK
//

@interface Kumulos (PushProtected)

- (void) pushInit;
- (void) pushHandleOpenWithUserInfo:(NSDictionary*)userInfo;

@end
