//
//  KumulosInApp.m
//  KumulosSDK
//

#import "KumulosInApp.h"
#import "Kumulos+Protected.h"

@implementation KSInAppInboxItem

+ (instancetype) fromInboxItemEntity:(KSInAppMessageEntity*)entity {
    KSInAppInboxItem* item = [KSInAppInboxItem new];

    item->_id = entity.id;
    item->_title = entity.inboxConfig[@"title"];
    item->_subtitle = entity.inboxConfig[@"subtitle"];
    item->_availableFrom = entity.inboxFrom;
    item->_availableTo = entity.inboxTo;
    item->_dismissedAt = entity.dismissedAt;

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
    if (!Kumulos.shared.inAppHelper.messagesContext) {
        return @[];
    }

    NSMutableArray<KSInAppInboxItem*>* __block results = [NSMutableArray new];

    [Kumulos.shared.inAppHelper.messagesContext performBlockAndWait:^{
        NSManagedObjectContext* context = Kumulos.shared.inAppHelper.messagesContext;

        NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
        [fetchRequest setIncludesPendingChanges:NO];
        [fetchRequest setReturnsObjectsAsFaults:NO];
        [fetchRequest setPropertiesToFetch:@[@"id", @"inboxConfig", @"inboxFrom", @"inboxTo", @"dismissedAt"]];
        NSPredicate* onlyInboxItems = [NSPredicate
                                       predicateWithFormat:@"(inboxConfig != %@)",
                                       nil];
        NSSortDescriptor* sortBy = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
        [fetchRequest setSortDescriptors:@[sortBy]];
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

+ (KSInAppMessagePresentationResult)presentInboxMessage:(KSInAppInboxItem *)item {
    if (![item isAvailable]) {
        return KSInAppMessagePresentationExpired;
    }

    BOOL result = [Kumulos.shared.inAppHelper presentMessageWithId:item.id];

    return result ? KSInAppMessagePresentationPresented : KSInAppMessagePresentationFailed;
}

+ (BOOL)deleteMessageFromInbox:(KSInAppInboxItem *)item {
    return [Kumulos.shared.inAppHelper deleteMessageFromInbox:item.id];
}

@end

