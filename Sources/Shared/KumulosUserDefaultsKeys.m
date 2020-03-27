//
//  KumulosUserDefaultsKeys.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import <Foundation/Foundation.h>


#import "KumulosUserDefaultsKeys.h"

NSString* const KumulosApiKey = @"KumulosApiKey";
NSString* const KumulosSecretKey = @"KumulosSecretKey";
NSString* const KumulosInstallUUID = @"KumulosUUID";
NSString* const KumulosUserID = @"KumulosCurrentUserID";
NSString* const KumulosBadgeCount = @"KumulosBadgeCount";

//exist only in standard defaults for app
NSString* const KumulosMigratedToGroups = @"KumulosDidMigrateToAppGroups";
NSString* const KumulosMessagesLastSyncTime = @"KumulosMessagesLastSyncTime";
NSString* const KumulosInAppConsented = @"KumulosInAppConsented";

//exist only in standard defaults for extension
NSString* const KumulosDynamicCategory = @"__kumulos__dynamic__categories__";

@implementation KumulosUserDefaultsKeys

+ (NSArray*) getSharedKeys{
    return @[KumulosApiKey, KumulosSecretKey, KumulosInstallUUID, KumulosUserID, KumulosBadgeCount];
}

@end



