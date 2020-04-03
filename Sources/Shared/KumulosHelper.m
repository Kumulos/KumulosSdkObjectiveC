//
//  KumulosHelper.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import <Foundation/Foundation.h>
#import "KumulosHelper.h"
#import "KumulosUserDefaultsKeys.h"
#import "KSKeyValPersistenceHelper.h"


@implementation KumulosHelper

static NSString* _Nonnull const userIdLocker = @"";

+ (NSString*) installId {
    @synchronized (self) {
        NSString* installId = [[NSUserDefaults standardUserDefaults] objectForKey:KSPrefsKeyInstallUUID];
        
        if (!installId) {
            installId = [[[NSUUID UUID] UUIDString] lowercaseString];
            [[NSUserDefaults standardUserDefaults] setObject:installId forKey:KSPrefsKeyInstallUUID];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        return installId;
    }
}


+ (NSString*) currentUserIdentifier {
    @synchronized (userIdLocker) {
        NSString* userId = [NSUserDefaults.standardUserDefaults objectForKey:KSPrefsKeyUserID];
        if (userId) {
            return userId;
        }
    }

    return KumulosHelper.installId;
}

+ (NSString*) userIdLocker{
    return userIdLocker;
}

#if TARGET_OS_IOS
+ (NSNumber*) getBadgeFromUserInfo:(NSDictionary*)userInfo{
    NSDictionary* custom = userInfo[@"custom"];
    NSDictionary* aps = userInfo[@"aps"];
    
    NSNumber* incrementBy = custom[@"badge_inc"];
    NSNumber* badge = aps[@"badge"];
    
    if (badge == nil){
        return nil;
    }
    
    // Note in case of no cache, server sends the increment value in the badge field too, so works as badge = 0 + badge_inc
    NSNumber* newBadge = badge;
    NSNumber* currentBadgeCount = [KSKeyValPersistenceHelper objectForKey:KSPrefsKeyBadgeCount];
    if (incrementBy != nil && currentBadgeCount != nil){
        newBadge = [NSNumber numberWithInt: currentBadgeCount.intValue + incrementBy.intValue];

        if (newBadge.intValue < 0) {
            newBadge = @0;
        }
    }
    
    return newBadge;
}
#endif

@end
