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
@property (nonatomic,readonly) NSDate* _Nonnull sentAt;
@property (nonatomic,readonly) NSDictionary* _Nullable data;

- (BOOL) isRead;
- (NSURL* _Nullable) getImageUrl;
- (NSURL* _Nullable) getImageUrl:(int)width;

@end

@interface InAppInboxSummary : NSObject
@property (nonatomic,readonly) int totalCount;
@property (nonatomic,readonly) int unreadCount;
+ (instancetype _Nonnull) init:(int)totalCount unreadCount:(int)unreadCount;
@end

typedef void (^ _Nullable InboxSummaryBlock)(InAppInboxSummary* _Nullable inboxSummary);


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

+ (BOOL) deleteMessageFromInbox:(KSInAppInboxItem* _Nonnull)item;

+ (BOOL) markAsRead:(KSInAppInboxItem* _Nonnull)item;

+ (BOOL) markAllInboxItemsAsRead;

+ (void) getInboxSummaryAsync:(InboxSummaryBlock)inboxSummaryBlock;

@end
