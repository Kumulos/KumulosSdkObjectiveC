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

+ static (NSString *)getCategoryIdForMessageId:(int)notificationId {
    return [NSString stringWithFormat:DYNAMIC_CATEGORY_IDENTIFIER, notificationId];
}

+ static (void) registerCategory:(UNNotificationCategory*)category {
    NSMutableSet<UNNotificationCategory*>* categorySet = [sharedInstance.getExistingCategories];
    NSMutableArray<NSString *>* storedDynamicCategories = [sharedInstance.getExistingDynamicCategoriesList];
    
    [categorySet addObject:category]
    [storedDynamicCategories addObject:category.identifier]
    
    [sharedInstance.pruneCategoriesAndSave categories: categorySet, currentCategories: storedDynamicCategories]
    
    // Force a reload of the categories
    [sharedInstance.getExistingCategories];
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
       NSString* existingArray = [[NSUserDefaults standardUserDefaults] objectForKey:DYNAMIC_CATEGORY_USER_DEFAULTS_KEY];
       
        if (existingArray != nil) {
            return existingArray;
        }
        
       NSMutableArray *newArray = [NSMutableArray init];
       
       [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:DYNAMIC_CATEGORY_USER_DEFAULTS_KEY];
       [[NSUserDefaults standardUserDefaults] synchronize];
   
       
       return newArray;
   }
}

- (void)pruneCategoriesAndSave:(NSMutableSet<UNNotificationCategory*>*)categories currentCategories: (NSMutableArray<NSString*>*)currentCategories {
    /*
        if (dynamicCategories.count <= MAX_DYNAMIC_CATEGORIES) {
            UNUserNotificationCenter.current().setNotificationCategories(categories)
            UserDefaults.standard.set(dynamicCategories, forKey: DYNAMIC_CATEGORY_USER_DEFAULTS_KEY)
            return
        }
        
        let categoriesToRemove = dynamicCategories.prefix(dynamicCategories.count - MAX_DYNAMIC_CATEGORIES)
        
        let prunedCategories = categories.filter { (category) -> Bool in
            return categoriesToRemove.firstIndex(of: category.identifier) == nil
        }
        
        let prunedDynamicCategories = dynamicCategories.filter { (cat) -> Bool in
            return categoriesToRemove.firstIndex(of: cat) == nil
        }
        
        UNUserNotificationCenter.current().setNotificationCategories(prunedCategories)
        UserDefaults.standard.set(prunedDynamicCategories, forKey: DYNAMIC_CATEGORY_USER_DEFAULTS_KEY)
    }*/
}



@end
