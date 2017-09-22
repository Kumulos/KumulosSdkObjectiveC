//
//  Kumulos+Location.m
//  KumulosSDK
//
//

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

    NSString* path = [NSString stringWithFormat:@"/v1/app-installs/%@/location", [Kumulos installId]];

    [self.statsHttpClient PUT:path parameters:jsonDict success:^(NSURLSessionDataTask* task, id response) {
        // Noop
    } failure:^(NSURLSessionDataTask* task, NSError* error) {
        // Noop
    }];
}

@end
