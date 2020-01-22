//
//  CategoryHelper.h
//  KumulosSDK
//
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface KSCategoryHelper : NSObject

+ (KSCategoryHelper *)sharedInstance;

+  (NSString *)getCategoryIdForMessageId:(NSNumber*)messageId;

+  (void) registerCategory:(UNNotificationCategory*)category;

- (NSMutableSet<UNNotificationCategory*>*)getExistingCategories;

- (NSMutableArray<NSString*>*)getExistingDynamicCategoriesList;

- (void)pruneCategoriesAndSave:(NSMutableSet<UNNotificationCategory*>*)categories withDynamicCategories: (NSMutableArray<NSString*>*)dynamicCategories;

@end
