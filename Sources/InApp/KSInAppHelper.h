//
//  KSInAppHelper.h
//  KumulosSDK
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "../Kumulos.h"
#import "KSInAppModels.h"
#import "../Kumulos+Push.h"
#import "../KumulosInApp.h"

extern NSString* _Nonnull const KSInAppPresentedImmediately;
extern NSString* _Nonnull const KSInAppPresentedNextOpen;
extern NSString* _Nonnull const KSInAppPresentedFromInbox;

@interface KSJsonValueTransformer : NSValueTransformer
@end

@interface KSInAppHelper : NSObject

@property (nonatomic) NSManagedObjectContext* _Nullable messagesContext;

- (instancetype _Nullable) initWithKumulos:(Kumulos* _Nonnull) kumulos;
- (void) updateUserConsent:(BOOL)consentGiven;
- (void) sync:(void (^_Nullable)(int result))onComplete;
- (void) handleMessageOpened:(KSInAppMessage* _Nonnull)message;
- (void) markMessageDismissed:(KSInAppMessage* _Nonnull)message;
- (void) handleAssociatedUserChange;
- (void) handlePushOpen:(KSPushNotification* _Nonnull)notification;
- (BOOL) presentMessageWithId:(NSNumber* _Nonnull)messageId;
- (BOOL) deleteMessageFromInbox:(NSNumber* _Nonnull)messageId;
- (BOOL) markInboxItemRead:(NSNumber* _Nonnull)withId shouldWait:(BOOL)shouldWait;
- (BOOL) markAllInboxItemsAsRead;
- (void) setOnInboxUpdated:(InboxUpdatedHandlerBlock)inboxUpdatedHandlerBlock;
- (void) maybeRunInboxUpdatedHandler:(BOOL)inboxNeedsUpdate;
- (void) readInboxSummary:(InboxSummaryBlock)inboxSummaryBlock;
@end
