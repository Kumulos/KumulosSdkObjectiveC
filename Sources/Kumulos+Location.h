//
//  Kumulos+Location.h
//  KumulosSDK
//
//

@import CoreLocation;

#import "Kumulos.h"

@interface Kumulos (Location)

/**
 * Updates the location of this installation in Kumulos
 * Accurate locaiton information is used for geofencing
 * @param location The current device location
 */
- (void) sendLocationUpdate:(CLLocation* _Nullable) location;

@end
