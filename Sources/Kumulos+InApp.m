//
//  Kumulos+InApp.m
//  KumulosSDK
//

#import "Kumulos+InApp.h"
#import "Kumulos+Protected.h"

@implementation Kumulos (InApp)

-(void)updateInAppConsentForUser:(BOOL)consentGiven {
    if (self.config.inAppConsentStrategy != KSInAppConsentStrategyExplicitByUser) {
        [NSException raise:@"Kumulos: Invalid In-app consent strategy" format:@"You can only manage in-app messaging consent when the feature is enabled and strategy is set to KSInAppConsentStrategyExplicitByUser"];
        return;
    }

    [self.inAppHelper updateUserConsent:consentGiven];
}

@end
