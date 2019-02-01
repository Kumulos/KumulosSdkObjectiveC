//
//  Kumulos+Kumulos_Analytics.m
//  KumulosSDK iOS
//

#import "KumulosEvents.h"
#import "Kumulos+Analytics.h"
#import "Kumulos+Protected.h"

static NSString* _Nonnull const userIdLocker = @"";

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
    @synchronized (userIdLocker) {
        NSString* userId = [NSUserDefaults.standardUserDefaults objectForKey:KUMULOS_USER_ID_KEY];
        if (userId) {
            return userId;
        }
    }

    return Kumulos.installId;
}

- (void) clearUserAssociation {
    NSString* currentUserId = nil;
    @synchronized (userIdLocker) {
        currentUserId = [NSUserDefaults.standardUserDefaults objectForKey:KUMULOS_USER_ID_KEY];
    }

    NSDictionary* props = @{@"oldUserIdentifier": currentUserId ?: NSNull.null};
    [self trackEvent:KumulosEventUserAssociationCleared withProperties:props];

    @synchronized (userIdLocker) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:KUMULOS_USER_ID_KEY];
    }
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

    @synchronized (userIdLocker) {
        [NSUserDefaults.standardUserDefaults setObject:userIdentifier forKey:KUMULOS_USER_ID_KEY];
    }

    [self.analyticsHelper trackEvent:KumulosEventUserAssociated withProperties:params];
}

@end
