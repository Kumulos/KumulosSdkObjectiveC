//
//  KumulosHelper.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import <Foundation/Foundation.h>
#import "KumulosHelper.h"
#import "KumulosUserDefaultsKeys.h"




@implementation KumulosHelper

static NSString* _Nonnull const userIdLocker = @"";

+ (NSString*) installId {
    @synchronized (self) {
        NSString* installId = [[NSUserDefaults standardUserDefaults] objectForKey:KumulosInstallUUID];
        
        if (!installId) {
            installId = [[[NSUUID UUID] UUIDString] lowercaseString];
            [[NSUserDefaults standardUserDefaults] setObject:installId forKey:KumulosInstallUUID];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        return installId;
    }
}


+ (NSString*) currentUserIdentifier {
    @synchronized (userIdLocker) {
        NSString* userId = [NSUserDefaults.standardUserDefaults objectForKey:KumulosUserID];
        if (userId) {
            return userId;
        }
    }

    return KumulosHelper.installId;
}

+ (NSString*) userIdLocker{
    return userIdLocker;
}


@end
