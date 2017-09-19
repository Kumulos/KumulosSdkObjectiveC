//
//  Kumulos+Stats.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import "Kumulos.h"
@import CoreLocation;

@interface Kumulos (Stats)

- (void) statsSendInstallInfo;
- (void) sendLocationUpdate:(CLLocation*) location;

@end

typedef NS_ENUM(NSInteger, OSTypeID) {
    OSTypeIDiOS = 1,
    OSTypeIDOSX,
    OSTypeIDAndroid,
    OSTypeIDWindowsPhone,
    OSTypeIDWindows
};

typedef NS_ENUM(NSInteger, SDKTypeID) {
    SDKTypeObjC = 1,
    SDKTypeJavaSDK,
    SDKTypeCSharp,
    SDKTypeSwift
};

typedef NS_ENUM(NSInteger, RuntimeType) {
    RuntimeTypeUnknown = 0,
    RuntimeTypeNative,
    RuntimeTypeXamarin,
    RuntimeTypeCordova,
    RuntimeTypeJavaRuntime
};

typedef NS_ENUM(NSInteger, TargetType) {
    TargetTypeDebug = 1,
    TargetTypeRelease
};
