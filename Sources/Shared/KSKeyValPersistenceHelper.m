//
//  KSKeyValPersistenceHelper.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import <Foundation/Foundation.h>
#import "KSKeyValPersistenceHelper.h"
#import "KSAppGroupsHelper.h"
#import "KumulosUserDefaultsKeys.h"

@implementation KSKeyValPersistenceHelper


+ (void)setObject:(id)value forKey:(NSString*)forKey {
    [[KSKeyValPersistenceHelper getUserDefaults] setObject:value forKey:forKey];
}

+ (id)objectForKey:(NSString*) forKey {
    return [[KSKeyValPersistenceHelper getUserDefaults] objectForKey:forKey];
}

+ (void)removeObjectForKey:(NSString*) forKey {
    [[KSKeyValPersistenceHelper getUserDefaults] removeObjectForKey:forKey];
}

+ (void)maybeMigrateUserDefaultsToAppGroups {
    NSUserDefaults* standardDefaults = NSUserDefaults.standardUserDefaults;
    NSString* haveMigratedKey = KumulosMigratedToGroups;
    
    if (![KSAppGroupsHelper isKumulosAppGroupDefined]){
        [standardDefaults setObject:@(NO) forKey:haveMigratedKey];
        return;
    }
    
    NSUserDefaults* groupDefaults = [[NSUserDefaults alloc] initWithSuiteName: [KSAppGroupsHelper getKumulosGroupName]];
    if (groupDefaults == nil){return;}
    if ([groupDefaults boolForKey:haveMigratedKey] && [standardDefaults boolForKey:haveMigratedKey]){
        return;
    }
    
    NSDictionary<NSString*, id>* defaultsAsDict = [standardDefaults dictionaryRepresentation];
    
    for (NSString* key in [KumulosUserDefaultsKeys getSharedKeys]){
        [groupDefaults setObject:defaultsAsDict[key] forKey: key];
    }
    
    [standardDefaults setObject:@(YES) forKey:haveMigratedKey];
    [groupDefaults setObject:@(YES) forKey:haveMigratedKey];
}

+ (NSUserDefaults*)getUserDefaults {
    if (![KSAppGroupsHelper isKumulosAppGroupDefined]){
        return NSUserDefaults.standardUserDefaults;
    }
    
    NSUserDefaults*suiteUserDefaults = [[NSUserDefaults alloc] initWithSuiteName: [KSAppGroupsHelper getKumulosGroupName]];
    if (suiteUserDefaults != nil){
        return suiteUserDefaults;
    }
    
    return NSUserDefaults.standardUserDefaults;
}


@end
