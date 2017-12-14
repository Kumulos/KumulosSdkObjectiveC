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

- (void) associateUserWithInstall:(NSString *)userIdentifier {
    if (!userIdentifier || [userIdentifier isEqualToString:@""]) {
        NSLog(@"User identifier cannot be empty, aborting!");
        return;
    }
    
    NSDictionary* params = @{ @"id": userIdentifier };
    NSString* path = [NSString stringWithFormat:@"/v1/app-installs/%@/user-id", Kumulos.installId];
    
    [self.statsHttpClient PUT:path parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // Noop
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // Noop
    }];
}

@end
