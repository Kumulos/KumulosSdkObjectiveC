//
//  Kumulos+InApp.h
//  KumulosSDK
//

#import "Kumulos.h"

NS_ASSUME_NONNULL_BEGIN

@interface Kumulos (InApp)

-(void) updateInAppConsentForUser:(BOOL)consentGiven;

@end

NS_ASSUME_NONNULL_END
