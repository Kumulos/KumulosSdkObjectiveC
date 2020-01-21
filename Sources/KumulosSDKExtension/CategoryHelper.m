//
//  CategoryHelper.m
//  KumulosSDK
//
//
#import "CategoryHelper.h"

static int const MAX_DYNAMIC_CATEGORIES = 128;
static NSString * const DYNAMIC_CATEGORY_USER_DEFAULTS_KEY = @"__kumulos__dynamic__categories__";
static NSString * const DYNAMIC_CATEGORY_IDENTIFIER = @"__kumulos_category_%d__";

@implementation CategoryHelper

+ (CategoryHelper *)sharedInstance {
    static CategoryHelper *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [CategoryHelper new];
    });
    return sharedInstance;
}

+ (NSString *)getCategoryIdForMessageId:(int)notificationId {
    return [NSString stringWithFormat:DYNAMIC_CATEGORY_IDENTIFIER, notificationId];
}

+ (void) registerCategory:(UNNotificationCategory*)category {
    NSMutableSet<UNNotificationCategory*>* categorySet = [CategoryHelper.sharedInstance getExistingCategories];
    NSMutableArray<NSString *>* storedDynamicCategories = [CategoryHelper.sharedInstance getExistingDynamicCategoriesList];
    
    [categorySet addObject:category];
    [storedDynamicCategories addObject:category.identifier];
    
    [CategoryHelper.sharedInstance pruneCategoriesAndSave: categorySet withDynamicCategories: storedDynamicCategories];
    
    // Force a reload of the categories
    [CategoryHelper.sharedInstance getExistingCategories];
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

- (NSMutableArray<NSString *>*)getExistingDynamicCategoriesList {
    @synchronized (self) {
       NSMutableArray<NSString*> *existingArray = [[NSUserDefaults standardUserDefaults] objectForKey:DYNAMIC_CATEGORY_USER_DEFAULTS_KEY];
       
        if (existingArray != nil) {
            return existingArray;
        }
        
       NSMutableArray *newArray = [NSMutableArray init];
       
       [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:DYNAMIC_CATEGORY_USER_DEFAULTS_KEY];
       [[NSUserDefaults standardUserDefaults] synchronize];
   
       
       return newArray;
   }
}

- (void)pruneCategoriesAndSave:(NSMutableSet<UNNotificationCategory*>*)categories withDynamicCategories: (NSMutableArray<NSString*>*)dynamicCategories {
    if (dynamicCategories.count <= MAX_DYNAMIC_CATEGORIES) {
        [UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:categories];
        [[NSUserDefaults standardUserDefaults] setObject:dynamicCategories forKey:DYNAMIC_CATEGORY_USER_DEFAULTS_KEY];
        return;
    }
    
     NSMutableSet<NSString *> *categoriesToRemove = [NSMutableSet new];
    
    for (int i = (int)dynamicCategories.count - MAX_DYNAMIC_CATEGORIES; i >= 0; i--)
        [categoriesToRemove addObject:dynamicCategories[i]];
    
    NSMutableSet<UNNotificationCategory*> *newCategories = [NSMutableSet new];
    NSMutableArray<NSString*> *newDynamicCategories = [NSMutableArray init];
    
    for(UNNotificationCategory *category in categories)
        if (![categoriesToRemove containsObject:category.identifier])
            [newCategories addObject: category];
    
    for (NSString *dynamicCategory in dynamicCategories)
        if (![categoriesToRemove containsObject:dynamicCategory])
            [newDynamicCategories addObject:dynamicCategory];
    
    [UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:newCategories];
    [[NSUserDefaults standardUserDefaults] setObject:newDynamicCategories forKey:DYNAMIC_CATEGORY_USER_DEFAULTS_KEY];
}

@end
