//
//  KumulosSDK.h
//  KumulosSDK
//
//

#import <UIKit/UIKit.h>

//! Project version number for KumulosSDK.
FOUNDATION_EXPORT double KumulosSDKVersionNumber;

//! Project version string for KumulosSDK.
FOUNDATION_EXPORT const unsigned char KumulosSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Sources/PublicHeader.h>

#import "Kumulos.h"

#ifdef TARGET_OS_IOS
#import "Kumulos+Push.h"
#import "KumulosPushSubscriptionManager.h"
#endif

#import "KSAPIOperation.h"
#import "KSAPIResponse.h"

