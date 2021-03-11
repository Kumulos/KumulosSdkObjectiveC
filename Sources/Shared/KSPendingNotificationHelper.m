//
//  KSPendingNotificationHelper.m
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 10/03/2021.
//

#import <Foundation/Foundation.h>

#import "KSPendingNotificationHelper.h"
#import "KSKeyValPersistenceHelper.h"
#import "KumulosUserDefaultsKeys.h"

@implementation KSPendingNotificationHelper

+ (void)remove:(NSNumber*)notificationId {
    NSMutableArray<KSPendingNotification*>* pendingNotifications = [self readAll];
    
    for (NSUInteger i = 0; i < [pendingNotifications count]; i++) {
        KSPendingNotification *n = [pendingNotifications objectAtIndex:i];
        
        if ([n.notificationId isEqualToNumber:notificationId]){
            [pendingNotifications removeObjectAtIndex:i];
            [self save:pendingNotifications];
            
            return;
        }
    }
}

+ (void)removeByIdentifier:(NSString*)identifier {
    NSMutableArray<KSPendingNotification*>* pendingNotifications = [self readAll];
    
    for (NSUInteger i = 0; i < [pendingNotifications count]; i++) {
        KSPendingNotification *n = [pendingNotifications objectAtIndex:i];
        
        if ([n.identifier isEqualToString:identifier]){
            [pendingNotifications removeObjectAtIndex:i];
            [self save:pendingNotifications];
            
            return;
        }
    }
}

+ (void)add:(KSPendingNotification*)notification {
    NSMutableArray<KSPendingNotification*>* pendingNotifications = [self readAll];
    for (KSPendingNotification* n in pendingNotifications) {
        if ([n.notificationId isEqualToNumber:notification.notificationId]){
            return;
        }
    }
    
    [pendingNotifications addObject:notification];
    [self save:pendingNotifications];
}

+ (NSMutableArray<KSPendingNotification*>*)readAll{
    
    NSMutableArray<KSPendingNotification*>* pendingNotifications = [NSMutableArray array];
    
    NSData *encoded = [KSKeyValPersistenceHelper objectForKey:KSPrefsKeyPendingNotifications];
    if (encoded == nil){
        return pendingNotifications;
    }
    
    if (@available(iOS 11.0, *)) {
        NSSet *set = [NSSet setWithArray:@[[NSMutableArray class],[KSPendingNotification class]]];
        NSError* err = nil;
        NSMutableArray<KSPendingNotification*>* result = [NSKeyedUnarchiver unarchivedObjectOfClasses:set fromData: encoded error: &err];
        if (err == nil){
            pendingNotifications = result;
        }
    } else {
        pendingNotifications = [NSKeyedUnarchiver unarchiveObjectWithData:encoded];
    }
    
    return pendingNotifications;
}

+ (void)save:(NSMutableArray<KSPendingNotification*>*)pendingNotifications {
   
    NSData *encoded = nil;
    if (@available(iOS 11.0, *)) {
        NSError* err = nil;
        encoded = [NSKeyedArchiver archivedDataWithRootObject:pendingNotifications requiringSecureCoding:YES error:&err];
        if (err != nil){
            return;
        }
    } else {
        encoded = [NSKeyedArchiver archivedDataWithRootObject:pendingNotifications];
    }
    
    [KSKeyValPersistenceHelper setObject:encoded forKey:KSPrefsKeyPendingNotifications];
}


@end
