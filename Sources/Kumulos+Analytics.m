//
//  Kumulos+Kumulos_Analytics.m
//  KumulosSDK iOS
//

#import "Kumulos+Analytics.h"
#import "Kumulos+Protected.h"

@implementation Kumulos (Analytics)

- (void) trackEvent:(NSString *)eventType withProperties:(NSDictionary *)properties {
    [self.analyticsHelper trackEvent:eventType withProperties:properties];
}

@end
