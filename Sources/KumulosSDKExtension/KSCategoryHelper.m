//
//  CategoryHelper.m
//  KumulosSDK
//
//
#import "KSCategoryHelper.h"

static int const MAX_DYNAMIC_CATEGORIES = 128;
static NSString * const DYNAMIC_CATEGORY_USER_DEFAULTS_KEY = @"__kumulos__dynamic__categories__";
static NSString * const DYNAMIC_CATEGORY_IDENTIFIER = @"__kumulos_category_%d__";

@implementation KSCategoryHelper

+ (KSCategoryHelper *)sharedInstance {
    static KSCategoryHelper *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [KSCategoryHelper new];
    });
    return sharedInstance;
}

+ (NSString *)getCategoryIdForMessageId:(NSNumber*)notificationId {
    return [NSString stringWithFormat:DYNAMIC_CATEGORY_IDENTIFIER, notificationId.intValue];
}

+ (void) registerCategory:(UNNotificationCategory*)category {
    NSMutableSet<UNNotificationCategory*>* categorySet = [KSCategoryHelper.sharedInstance getExistingCategories];
    NSMutableArray<NSString*>* storedDynamicCategories = [KSCategoryHelper.sharedInstance getExistingDynamicCategoriesList];
    
    [categorySet addObject:category];
    [storedDynamicCategories addObject:category.identifier];
    
    [KSCategoryHelper.sharedInstance pruneCategoriesAndSave: categorySet withDynamicCategories: storedDynamicCategories];
    
    // Force a reload of the categories
    [KSCategoryHelper.sharedInstance getExistingCategories];
}


- (NSMutableSet<UNNotificationCategory*>*)getExistingCategories {
    __block NSMutableSet* allCategories;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [notificationCenter getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> *categories) {
        allCategories = [categories mutableCopy];
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return allCategories;
}

- (NSMutableArray<NSString*>*)getExistingDynamicCategoriesList {
    @synchronized (self) {
        NSMutableArray<NSString*> *existingArray = [[NSUserDefaults standardUserDefaults] objectForKey:DYNAMIC_CATEGORY_USER_DEFAULTS_KEY];

        if (existingArray != nil) {
            return [existingArray mutableCopy];
        }

        NSMutableArray<NSString*> *newArray = [NSMutableArray<NSString*> new];

        [NSUserDefaults.standardUserDefaults setObject:newArray forKey:DYNAMIC_CATEGORY_USER_DEFAULTS_KEY];
        [NSUserDefaults.standardUserDefaults synchronize];

        return newArray;
   }
}

- (void)pruneCategoriesAndSave:(NSMutableSet<UNNotificationCategory*>*)categories withDynamicCategories: (NSMutableArray<NSString*>*)dynamicCategories {
    if (dynamicCategories.count <= MAX_DYNAMIC_CATEGORIES) {
        [UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:categories];
        [NSUserDefaults.standardUserDefaults setObject:dynamicCategories forKey:DYNAMIC_CATEGORY_USER_DEFAULTS_KEY];
        [NSUserDefaults.standardUserDefaults synchronize];
        return;
    }
    
    NSMutableSet<NSString*> *categoriesToRemove = [NSMutableSet new];
    
    int numCategoriesToRemove = (int)dynamicCategories.count - MAX_DYNAMIC_CATEGORIES;
    
    for (int i = 0; i < numCategoriesToRemove; i++)
        [categoriesToRemove addObject:dynamicCategories[i]];
    
    NSMutableSet<UNNotificationCategory*> *newCategories = [NSMutableSet new];
    NSMutableArray<NSString*> *newDynamicCategories = [NSMutableArray<NSString*> new];
    
    for(UNNotificationCategory *category in categories)
        if (![categoriesToRemove containsObject:category.identifier])
            [newCategories addObject: category];
    
    for (NSString *dynamicCategory in dynamicCategories)
        if (![categoriesToRemove containsObject:dynamicCategory])
            [newDynamicCategories addObject:dynamicCategory];
    
    [UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:newCategories];
    [NSUserDefaults.standardUserDefaults setObject:newDynamicCategories forKey:DYNAMIC_CATEGORY_USER_DEFAULTS_KEY];
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
