//
//  KumulosUserDefaultsKeys.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import <Foundation/Foundation.h>


#import "KumulosUserDefaultsKeys.h"

NSString* const KSPrefsKeyApiKey = @"KumulosApiKey";
NSString* const KSPrefsKeySecretKey = @"KumulosSecretKey";
NSString* const KSPrefsKeyInstallUUID = @"KumulosUUID";
NSString* const KSPrefsKeyUserID = @"KumulosCurrentUserID";
NSString* const KSPrefsKeyBadgeCount = @"KumulosBadgeCount";

//exist only in standard defaults for app
NSString* const KSPrefsKeyMigratedToGroups = @"KumulosDidMigrateToAppGroups";
NSString* const KSPrefsKeyMessagesLastSyncTime = @"KumulosMessagesLastSyncTime";
NSString* const KSPrefsKeyInAppConsented = @"KumulosInAppConsented";

//exist only in standard defaults for extension
NSString* const KSPrefsKeyDynamicCategory = @"__kumulos__dynamic__categories__";

@implementation KumulosUserDefaultsKeys

+ (NSArray*) getSharedKeys{
    return @[KSPrefsKeyApiKey, KSPrefsKeySecretKey, KSPrefsKeyInstallUUID, KSPrefsKeyUserID, KSPrefsKeyBadgeCount];
}

@end



