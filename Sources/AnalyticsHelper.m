//
//  AnalyticsHelper.m
//  KumulosSDK iOS
//

@import CoreData;
#import "AnalyticsHelper.h"
#import "Kumulos+Protected.h"

@interface AnalyticsHelper ()

@property (nonatomic) Kumulos* _Nonnull kumulos;
@property NSManagedObjectContext* analyticsContext;

@end

@implementation AnalyticsHelper

#pragma mark - Initialization

- (instancetype _Nullable) initWithKumulos:(Kumulos *)kumulos {
    if (self = [super init]) {
        self.kumulos = kumulos;
        [self initContext];
        [self registerListeners];
        [self syncEvents];
    }
    
    return self;
}

- (void) initContext {
    NSURL* url = [[NSBundle bundleForClass:[self class]] URLForResource:@"KAnalyticsModel" withExtension:@"momd"];
    
    if (!url) {
        NSLog(@"Failed to find analytics models");
        return;
    }
    
    NSManagedObjectModel* objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    
    if (!objectModel) {
        NSLog(@"Failed to create object model");
        return;
    }
    
    NSPersistentStoreCoordinator* storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:objectModel];
    
    NSURL* docsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* storeUrl = [NSURL URLWithString:@"KAnalyticsDb.sqlite" relativeToURL:docsUrl];
    
    NSError* err = nil;
    [storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&err];
    
    if (err) {
        NSLog(@"Failed to set up persistent store: %@", err);
        return;
    }
    
    self.analyticsContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    self.analyticsContext.persistentStoreCoordinator = storeCoordinator;
}

- (void) registerListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameInactive) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
}

# pragma mark - Event tracking

- (void) trackEvent:(NSString *)eventType withProperties:(NSDictionary *)properties {
    if ([eventType isEqualToString:@""] || (properties && ![NSJSONSerialization isValidJSONObject:properties])) {
        NSLog(@"Ignoring invalid event with empty type or non-serializable properties");
    }
    
    [self.analyticsContext performBlock:^{
        NSManagedObjectContext* context = self.analyticsContext;
        
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
        
        if (!entity) {
            return;
        }
        
        NSManagedObject* event = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
        
        if (!event) {
            return;
        }
        
        NSError* err = nil;
        
        NSNumber* happenedAt = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
        NSString* uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
        NSData* propsJson = nil;
        
        if (properties) {
            propsJson = [NSJSONSerialization dataWithJSONObject:properties options:0 error:&err];
            
            if (err) {
                NSLog(@"Failed to encode properties, properties will be nil");
                propsJson = nil;
                err = nil;
            }
        }
        
        [event setValue:uuid forKey:@"uuid"];
        [event setValue:happenedAt forKey:@"happenedAt"];
        [event setValue:eventType forKey:@"eventType"];
        [event setValue:propsJson forKey:@"properties"];
        
        [context save:&err];
        
        if (err) {
            NSLog(@"Failed to record event: %@", err);
        }
    }];
}

- (void) syncEvents {
    
    // TODO

}

#pragma mark - App lifecycle delegates

- (void) appBecameActive {
    NSLog(@"APP DID BECOME ACTIVE");
    // Cancel session idle timer, record fg event if not already latched
}

- (void) appBecameInactive {
    NSLog(@"APP DID BECOME INACTIVE");
    // TODO start session idle timer, record current timestamp for bg event
}

- (void) appBecameBackground {
    NSLog(@"APP DID BECOME BACKGROUND");
    // Start sync timer for session idle timeout + 5s ?
    
    UIBackgroundTaskIdentifier __block bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"sync" expirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"DOING THE BG TASK SHIZZLE");
        NSLog(@"TIME REMAINING: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]);
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
}

- (void) appWillTerminate {
    NSLog(@"APP WILL TERMINATE");
    // Invalidate sync timer
    // TODO write bg event and invalidate idle timeout if not elapsed, try to sync?
}

@end
