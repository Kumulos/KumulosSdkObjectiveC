//
//  KumulosUserDefaultsKeys.h
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import <Foundation/Foundation.h>

extern NSString* _Nonnull const KSPrefsKeyApiKey;
extern NSString* _Nonnull const KSPrefsKeySecretKey;
extern NSString* _Nonnull const KSPrefsKeyInstallUUID;
extern NSString* _Nonnull const KSPrefsKeyUserID;
extern NSString* _Nonnull const KSPrefsKeyBadgeCount;

//exist only in standard defaults for app
extern NSString* _Nonnull const KSPrefsKeyMigratedToGroups;
extern NSString* _Nonnull const KSPrefsKeyMessagesLastSyncTime;
extern NSString* _Nonnull const KSPrefsKeyInAppConsented;

//exist only in standard defaults for extension
extern NSString* _Nonnull const KSPrefsKeyDynamicCategory;



@interface KumulosUserDefaultsKeys : NSObject

+ (NSArray* _Nonnull) getSharedKeys;

@end
