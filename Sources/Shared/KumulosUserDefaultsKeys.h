//
//  KumulosUserDefaultsKeys.h
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import <Foundation/Foundation.h>

extern NSString* _Nonnull const KumulosApiKey;
extern NSString* _Nonnull const KumulosSecretKey;
extern NSString* _Nonnull const KumulosInstallUUID;
extern NSString* _Nonnull const KumulosUserID;
extern NSString* _Nonnull const KumulosBadgeCount;

//exist only in standard defaults for app
extern NSString* _Nonnull const KumulosMigratedToGroups;
extern NSString* _Nonnull const KumulosMessagesLastSyncTime;
extern NSString* _Nonnull const KumulosInAppConsented;

//exist only in standard defaults for extension
extern NSString* _Nonnull const KumulosDynamicCategory;



@interface KumulosUserDefaultsKeys : NSObject

+ (NSArray* _Nonnull) getSharedKeys;

@end
