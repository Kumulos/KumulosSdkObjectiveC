//
//  KumulosUserDefaultsKeys.h
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import <Foundation/Foundation.h>

extern NSString* const KumulosApiKey;
extern NSString* const KumulosSecretKey;
extern NSString* const KumulosInstallUUID;
extern NSString* const KumulosUserID;
extern NSString* const KumulosBadgeCount;

//exist only in standard defaults for app
extern NSString* const KumulosMigratedToGroups;
extern NSString* const KumulosMessagesLastSyncTime;
extern NSString* const KumulosInAppConsented;

//exist only in standard defaults for extension
extern NSString* const KumulosDynamicCategory;



@interface KumulosUserDefaultsKeys : NSObject

+ (NSArray*) getSharedKeys;

@end
