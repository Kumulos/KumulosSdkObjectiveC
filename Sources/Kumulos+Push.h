//
//  Kumulos+Push.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kumulos.h"

@interface KSPushNotification : NSObject

@property (nonatomic,readonly) NSNumber* _Nonnull id;
@property (nonatomic,readonly) NSDictionary* _Nonnull data;
@property (nonatomic,readonly) NSURL* _Nullable url;
@property (nonatomic,readonly) NSDictionary* _Nullable inAppDeepLink;

@end

@interface Kumulos (Push)

/**
 * Requests a push token from the user.
 * 
 * Will prompt for alert, sound, and badge permissions.
 *
 * After the permission is granted, you should call Kumulos#pushRegisterWithDeviceToken to complete the registration flow.
 */
- (void) pushRequestDeviceToken;

/**
 * Registers the given device token with Kumulos for the current unique installation
 * @param deviceToken The device's push token
 */
- (void) pushRegisterWithDeviceToken:(NSData* _Nonnull)deviceToken;

/**
 Unsubscribe your device from the Kumulos Push service
 */
- (void) pushUnregister;

/**
 * Tracks a conversion from a notification object to let Kumulos know that the given push 'converted' the user
 * @param notification The remote notification model that was receieved by the device
 */
- (void) pushTrackOpenFromNotification:(KSPushNotification* _Nullable)notification;

@end
