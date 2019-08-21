//
//  KumulosInApp.h
//  KumulosSDK
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, KSInAppMessagePresentationResult) {
    KSInAppMessagePresentationPresented,
    KSInAppMessagePresentationExpired,
    KSInAppMessagePresentationFailed
};

@interface KSInAppInboxItem : NSObject

@property (nonatomic,readonly) NSNumber* _Nonnull id;
@property (nonatomic,readonly) NSString* _Nonnull title;
@property (nonatomic,readonly) NSString* _Nonnull subtitle;
@property (nonatomic,readonly) NSDate* _Nullable availableFrom;
@property (nonatomic,readonly) NSDate* _Nullable availableTo;
@property (nonatomic,readonly) NSDate* _Nullable dismissedAt;

@end

@interface KumulosInApp : NSObject

/**
 * Allows marking the currently-associated user as opted-in or -out for in-app messaging
 *
 * Only applies when the in-app consent management strategy is KSInAppConsentStrategyExplicitByUser
 *
 * @param consentGiven Whether the user opts in or out of in-app messaging
 */
+ (void) updateConsentForUser:(BOOL)consentGiven;

+ (NSArray<KSInAppInboxItem*>* _Nonnull) getInboxItems;

+ (KSInAppMessagePresentationResult) presentInboxMessage:(KSInAppInboxItem* _Nonnull)item;

@end
