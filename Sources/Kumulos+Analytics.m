//
//  Kumulos+Kumulos_Analytics.m
//  KumulosSDK iOS
//

#import "KumulosEvents.h"
#import "Kumulos+Analytics.h"
#import "Kumulos+Protected.h"
#import "Shared/KumulosHelper.h"
#import "Shared/KumulosUserDefaultsKeys.h"
#import "Shared/KSKeyValPersistenceHelper.h"
#import "Shared/KSAnalyticsHelper.h"

@implementation Kumulos (Analytics)

- (void) trackEvent:(NSString *)eventType withProperties:(NSDictionary *)properties {
    [self.analyticsHelper trackEvent:eventType withProperties:properties];
}

- (void) trackEventImmediately:(NSString *)eventType withProperties:(NSDictionary *)properties {
    [self.analyticsHelper trackEvent:eventType withProperties:properties flushingImmediately:YES];
}

- (void) associateUserWithInstall:(NSString *)userIdentifier {
    [self associateUserWithInstallImpl:userIdentifier attributes:nil];
}

- (void) associateUserWithInstall:(NSString *)userIdentifier attributes:(NSDictionary * _Nonnull)attributes {
    [self associateUserWithInstallImpl:userIdentifier attributes:attributes];
}

+ (NSString*) currentUserIdentifier {
    return KumulosHelper.currentUserIdentifier;
}

- (void) clearUserAssociation {
    NSString* currentUserId = nil;
    @synchronized (KumulosHelper.userIdLocker) {
        currentUserId = [KSKeyValPersistenceHelper objectForKey:KSPrefsKeyUserID];
    }

    NSDictionary* props = @{@"oldUserIdentifier": currentUserId ?: NSNull.null};
    [self trackEvent:KumulosEventUserAssociationCleared withProperties:props];

    @synchronized (KumulosHelper.userIdLocker) {
        [KSKeyValPersistenceHelper removeObjectForKey:KSPrefsKeyUserID];
    }

#if TARGET_OS_IOS
    if (currentUserId != nil && ![currentUserId isEqualToString:Kumulos.installId]) {
        [self.inAppHelper handleAssociatedUserChange];
    }
#endif
}

#pragma mark - Helpers

- (void) associateUserWithInstallImpl:(NSString *)userIdentifier attributes:(NSDictionary *)attributes {
    if (!userIdentifier || [userIdentifier isEqualToString:@""]) {
        NSLog(@"User identifier cannot be empty, aborting!");
        return;
    }

    NSDictionary* params;

    if (attributes != nil) {
        params = @{ @"id": userIdentifier, @"attributes": attributes };
    }
    else {
        params = @{ @"id": userIdentifier };
    }

    NSString* currentUserIdentifier = nil;
    @synchronized (KumulosHelper.userIdLocker) {
        currentUserIdentifier = [KSKeyValPersistenceHelper objectForKey:KSPrefsKeyUserID];
        [KSKeyValPersistenceHelper setObject:userIdentifier forKey:KSPrefsKeyUserID];
    }

    [self.analyticsHelper trackEvent:KumulosEventUserAssociated withProperties:params];

#if TARGET_OS_IOS
    if (currentUserIdentifier == nil || ![currentUserIdentifier isEqualToString:userIdentifier]) {
        [self.inAppHelper handleAssociatedUserChange];
    }
#endif
}

@end
