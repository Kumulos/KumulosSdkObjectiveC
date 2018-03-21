//
//  Kumulos+Location.m
//  KumulosSDK
//
//

#import "KumulosEvents.h"
#import "Kumulos+Location.h"
#import "Kumulos+Protected.h"

@implementation Kumulos (Location)

- (void) sendLocationUpdate:(CLLocation*) location {
    if (nil == location) {
        return;
    }

    NSDictionary *jsonDict = @{@"lat" : @(location.coordinate.latitude),
                               @"lng" : @(location.coordinate.longitude)
                               };
    
    [self.analyticsHelper trackEvent:KumulosEventLocationUpdated withProperties:jsonDict flushingImmediately:YES];
}

@end
