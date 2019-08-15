//
//  KSInAppHelper.h
//  KumulosSDK
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "../Kumulos.h"
#import "KSInAppModels.h"

extern NSString* _Nonnull const KSInAppPresentedImmediately;
extern NSString* _Nonnull const KSInAppPresentedNextOpen;
extern NSString* _Nonnull const KSInAppPresentedFromInbox;

@interface KSJsonValueTransformer : NSValueTransformer
@end

@interface KSInAppHelper : NSObject

- (instancetype _Nullable) initWithKumulos:(Kumulos* _Nonnull) kumulos;
- (void) updateUserConsent:(BOOL)consentGiven;
- (void) sync;
- (void) markMessageOpened:(KSInAppMessage* _Nonnull)message;
- (void) handleAssociatedUserChange;

@end
