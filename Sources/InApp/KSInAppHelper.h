//
//  KSInAppHelper.h
//  KumulosSDK
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "../Kumulos.h"
#import "KSInAppModels.h"
#import "../Kumulos+Push.h"

extern NSString* _Nonnull const KSInAppPresentedImmediately;
extern NSString* _Nonnull const KSInAppPresentedNextOpen;
extern NSString* _Nonnull const KSInAppPresentedFromInbox;

@interface KSJsonValueTransformer : NSValueTransformer
@end

@interface KSInAppHelper : NSObject

- (instancetype _Nullable) initWithKumulos:(Kumulos* _Nonnull) kumulos;
- (void) updateUserConsent:(BOOL)consentGiven;
- (void) sync:(void (^_Nullable)(int result))onComplete;
- (void) trackMessageOpened:(KSInAppMessage* _Nonnull)message;
- (void) markMessageDismissed:(KSInAppMessage* _Nonnull)message;
- (void) handleAssociatedUserChange;
- (void) handlePushOpen:(KSPushNotification* _Nonnull)notification;
@end
