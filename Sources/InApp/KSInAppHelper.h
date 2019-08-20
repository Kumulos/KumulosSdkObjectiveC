//
//  KSInAppHelper.h
//  KumulosSDK
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "../Kumulos.h"
#import "KSInAppMessage.h"

@interface KSJsonValueTransformer : NSValueTransformer
@end

@interface KSInAppHelper : NSObject

- (instancetype _Nullable) initWithKumulos:(Kumulos* _Nonnull) kumulos;
- (void) updateUserConsent:(BOOL)consentGiven;
- (void) sync;

@end
