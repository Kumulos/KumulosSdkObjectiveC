//
//  Kumulos+Kumulos_Analytics.h
//  KumulosSDK iOS
//

#import <Foundation/Foundation.h>
#import "Kumulos.h"

@interface Kumulos (Analytics)

- (void) trackEvent:(NSString* _Nonnull) eventType withProperties:(NSDictionary* _Nullable) properties;

@end
