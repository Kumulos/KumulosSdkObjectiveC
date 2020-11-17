//
//  KSKeyValPersistenceHelper.h
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

@interface KSKeyValPersistenceHelper : NSObject

+ (void)setObject:(id)value forKey:(NSString*)forKey;
+ (id)objectForKey:(NSString*) forKey;
+ (void)removeObjectForKey:(NSString*) forKey;
+ (void)maybeMigrateUserDefaultsToAppGroups;
+ (BOOL)boolForKey:(NSString*) forKey;
+ (void)setBool:(BOOL)value forKey:(NSString*)forKey;

@end
