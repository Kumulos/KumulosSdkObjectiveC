//
//  KumulosSDK.h
//  KumulosSDK
//
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

//! Project version number for KumulosSDK.
FOUNDATION_EXPORT double KumulosSDKVersionNumber;

//! Project version string for KumulosSDK.
FOUNDATION_EXPORT const unsigned char KumulosSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Sources/PublicHeader.h>

#import <KumulosSDK/Kumulos.h>


#if TARGET_OS_IOS
#import <KumulosSDK/Kumulos+DeepLinking.h>
#import <KumulosSDK/Kumulos+Push.h>
#import <KumulosSDK/KumulosPushSubscriptionManager.h>
#import <KumulosSDK/Kumulos+Location.h>
#import <KumulosSDK/Kumulos+Analytics.h>
#import <KumulosSDK/KumulosInApp.h>

#endif

#import <KumulosSDK/KSAPIOperation.h>
#import <KumulosSDK/KSAPIResponse.h>
