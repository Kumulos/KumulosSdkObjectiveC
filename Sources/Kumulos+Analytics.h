//
//  Kumulos+Kumulos_Analytics.h
//  KumulosSDK iOS
//

#import <Foundation/Foundation.h>
#import "Kumulos.h"

@interface Kumulos (Analytics)

/**
 * Logs an analytics event to the local database
 * @param eventType Unique identifier for the type of event
 * @param properties Optional meta-data about the event
 */
- (void) trackEvent:(NSString* _Nonnull) eventType withProperties:(NSDictionary* _Nullable) properties;

@end
