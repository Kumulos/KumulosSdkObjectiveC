//
//  KumulosInApp.h
//  KumulosSDK
//

#import <Foundation/Foundation.h>

@interface KumulosInApp : NSObject

/**
 * Allows marking the currently-associated user as opted-in or -out for in-app messaging
 *
 * Only applies when the in-app consent management strategy is KSInAppConsentStrategyExplicitByUser
 *
 * @param consentGiven Whether the user opts in or out of in-app messaging
 */
+ (void) updateConsentForUser:(BOOL)consentGiven;

@end
