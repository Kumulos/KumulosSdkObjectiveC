//
//  KumulosInApp.m
//  KumulosSDK
//

#import "KumulosInApp.h"
#import "Kumulos+Protected.h"

@interface KSInAppInboxItem()

@property (nonatomic,readonly) NSString* _Nullable imagePath;
@property (nonatomic,readonly) NSDate* _Nullable readAt;

@end

@implementation KSInAppInboxItem

int const DEFAULT_IMAGE_WIDTH = 300;

+ (instancetype) fromInboxItemEntity:(KSInAppMessageEntity*)entity {
    KSInAppInboxItem* item = [KSInAppInboxItem new];

    item->_id = [entity.id copy];
    item->_title = [entity.inboxConfig[@"title"] copy];
    item->_subtitle = [entity.inboxConfig[@"subtitle"] copy];
    item->_imagePath = ![entity.inboxConfig[@"imagePath"] isEqual:NSNull.null] ? [entity.inboxConfig[@"imagePath"] copy] : nil;
    item->_availableFrom = [entity.inboxFrom copy];
    item->_availableTo = [entity.inboxTo copy];
    item->_dismissedAt = [entity.dismissedAt copy];
    item->_readAt = [entity.readAt copy];
    item->_data= [entity.data copy];
    if (entity.sentAt != nil){
        item->_sentAt = [entity.sentAt copy];
    }
    else{
        item->_sentAt = [entity.updatedAt copy];
    }

    return item;
}

- (BOOL) isAvailable {
    if (self.availableFrom && [self.availableFrom timeIntervalSinceNow] > 0) {
        return NO;
    } else if (self.availableTo && [self.availableTo timeIntervalSinceNow] < 0) {
        return NO;
    }

    return YES;
}

- (BOOL) isRead {
    return self.readAt != nil;
}

- (NSURL* _Nullable) getImageUrl {
    return [self getImageUrl:DEFAULT_IMAGE_WIDTH];
}

- (NSURL* _Nullable) getImageUrl:(int)width {
    if (width <= 0 || self.imagePath == nil){
        return nil;
    }

    return [KSMediaHelper getCompletePictureUrl:self.imagePath width:(NSUInteger) (floor(width))];
}

@end

@implementation InAppInboxSummary

+ (instancetype) init:(int)totalCount unreadCount:(int)unreadCount {
    InAppInboxSummary* item = [InAppInboxSummary new];
    item->_totalCount = totalCount;
    item->_unreadCount = unreadCount;

    return item;
}

@end

@implementation KSInAppButtonPress

@synthesize deepLinkData;
@synthesize messageId;
@synthesize messageData;

// Note this initialiser is effectively private and declared in a category in KSInAppPresenter for use
// where it is needed
+ (instancetype) forInAppMessage:(KSInAppMessage*)message withDeepLink:(NSDictionary*)deepLinkData {
    KSInAppButtonPress* press = [KSInAppButtonPress new];
    press->deepLinkData = deepLinkData;
    press->messageId = message.id;
    press->messageData = message.data;

    return press;
}

@end

@implementation KumulosInApp

+ (void)updateConsentForUser:(BOOL)consentGiven {
    if (Kumulos.shared.config.inAppConsentStrategy != KSInAppConsentStrategyExplicitByUser) {
        [NSException raise:@"Kumulos: Invalid In-app consent strategy" format:@"You can only manage in-app messaging consent when the feature is enabled and strategy is set to KSInAppConsentStrategyExplicitByUser"];
        return;
    }

    [Kumulos.shared.inAppHelper updateUserConsent:consentGiven];
}

+ (NSArray<KSInAppInboxItem*>*)getInboxItems {
    NSManagedObjectContext* context = Kumulos.shared.inAppHelper.messagesContext;
    if (!context) {
        return @[];
    }

    NSMutableArray<KSInAppInboxItem*>* __block results = [NSMutableArray new];

    [context performBlockAndWait:^{
        NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
        [fetchRequest setIncludesPendingChanges:NO];
        [fetchRequest setPropertiesToFetch:@[@"id", @"inboxConfig", @"inboxFrom", @"inboxTo", @"dismissedAt", @"readAt", @"sentAt", @"data", @"updatedAt"]];
        NSPredicate* onlyInboxItems = [NSPredicate
                                       predicateWithFormat:@"(inboxConfig != %@)",
                                       nil];

        [fetchRequest setSortDescriptors: @[
            [[NSSortDescriptor alloc] initWithKey:@"sentAt" ascending:NO],
            [[NSSortDescriptor alloc] initWithKey:@"updatedAt" ascending:NO],
            [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO]
        ]];
        [fetchRequest setPredicate:onlyInboxItems];

        NSError* err = nil;
        NSArray<KSInAppMessageEntity*>* items = [context executeFetchRequest:fetchRequest error:&err];

        if (err != nil) {
            NSLog(@"Failed to fetch items: %@", err);
            return;
        }

        for (KSInAppMessageEntity* item in items) {
            KSInAppInboxItem* inboxItem = [KSInAppInboxItem fromInboxItemEntity:item];

            if (![inboxItem isAvailable]) {
                continue;
            }

            [results addObject:inboxItem];
        }
    }];

    return results;
}

+ (KSInAppMessagePresentationResult)presentInboxMessage:(KSInAppInboxItem*)item {
    if (![item isAvailable]) {
        return KSInAppMessagePresentationExpired;
    }

    BOOL result = [Kumulos.shared.inAppHelper presentMessageWithId:item.id];

    return result ? KSInAppMessagePresentationPresented : KSInAppMessagePresentationFailed;
}

+ (BOOL)deleteMessageFromInbox:(KSInAppInboxItem*)item {
    return [Kumulos.shared.inAppHelper deleteMessageFromInbox:item.id];
}

+ (BOOL)markAsRead:(KSInAppInboxItem*)item {
    if ([item isRead]){
        return NO;
    }

    BOOL res = [Kumulos.shared.inAppHelper markInboxItemRead:item.id shouldWait:true];
    [Kumulos.shared.inAppHelper maybeRunInboxUpdatedHandler:res];
    return res;
}

+ (BOOL)markAllInboxItemsAsRead {
    return [Kumulos.shared.inAppHelper markAllInboxItemsAsRead];
}

+ (void)setOnInboxUpdated:(InboxUpdatedHandlerBlock)inboxUpdatedHandlerBlock {
    if (Kumulos.shared.inAppHelper == nil){
        [NSException raise:@"Could not set InboxUpdatedHandler" format:@"Kumulos should be initialized before setting handler"];
        
        return;
    }
  
    [Kumulos.shared.inAppHelper setOnInboxUpdated:inboxUpdatedHandlerBlock];
}

+ (void)getInboxSummaryAsync:(InboxSummaryBlock)inboxSummaryBlock {
    [Kumulos.shared.inAppHelper readInboxSummary:inboxSummaryBlock];
}

@end
