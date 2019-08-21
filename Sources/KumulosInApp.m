//
//  KumulosInApp.m
//  KumulosSDK
//

#import "KumulosInApp.h"
#import "Kumulos+Protected.h"

@implementation KumulosInApp

+ (void)updateConsentForUser:(BOOL)consentGiven {
    if (Kumulos.shared.config.inAppConsentStrategy != KSInAppConsentStrategyExplicitByUser) {
        [NSException raise:@"Kumulos: Invalid In-app consent strategy" format:@"You can only manage in-app messaging consent when the feature is enabled and strategy is set to KSInAppConsentStrategyExplicitByUser"];
        return;
    }

    [Kumulos.shared.inAppHelper updateUserConsent:consentGiven];
}

@end

