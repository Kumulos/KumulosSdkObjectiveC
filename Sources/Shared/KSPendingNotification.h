//
//  KSPendingNotification.h
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 10/03/2021.
//

#ifndef KSPendingNotification_h
#define KSPendingNotification_h

@interface KSPendingNotification : NSObject<NSCoding, NSSecureCoding>


@property (nonatomic) NSNumber* _Nonnull notificationId;
@property (nonatomic) NSDate* _Nonnull dismissedAt;
@property (nonatomic) NSString* _Nonnull identifier;

- (instancetype _Nonnull) initWithId:(NSNumber* _Nonnull) notificationId dismissedAt:(NSDate* _Nonnull) dismissedAt identifier:(NSString* _Nonnull) identifier;

- (void)encodeWithCoder:(NSCoder * _Nonnull)encoder;
- (instancetype _Nonnull )initWithCoder:(NSCoder *_Nonnull)decoder;

@end

#endif /* KSPendingNotification_h */
