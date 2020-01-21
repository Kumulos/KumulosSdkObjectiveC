//
//  CategoryHelper.h
//  KumulosSDK
//
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface CategoryHelper : NSObject

+ (CategoryHelper *)sharedInstance;

- static (NSString *)getCategoryIdForMessageId:(int)messageId;

- static (void) registerCategory:(UNNotificationCategory*)category;

- (NSMutableSet<UNNotificationCategory*>*)getExistingCategories;

- (NSMutableArray<NSString *>)getExistingDynamicCategoriesList;

- (void)pruneCategoriesAndSave:(NSMutableSet<UNNotificationCategory*>)*categories currentCategories: (NSMutableArray<NSString*>*)currentCategories;

@end
