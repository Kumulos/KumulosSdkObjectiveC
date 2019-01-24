//
//  AnalyticsHelper.m
//  KumulosSDK iOS
//

#import "AnalyticsHelper.h"
#import "Kumulos+Protected.h"
#import "KumulosEvents.h"

@interface AnalyticsHelper ()

@property (nonatomic) Kumulos* _Nonnull kumulos;
@property NSManagedObjectContext* analyticsContext;
@property (atomic) BOOL startNewSession;
@property (atomic) NSTimer* sessionIdleTimer;
@property (atomic) NSDate* becameInactiveAt;
@property (atomic) UIBackgroundTaskIdentifier bgTask;

@end

@implementation KSEventModel : NSManagedObject

@synthesize identifier;
@synthesize eventType;
@synthesize happenedAt;
@synthesize properties;
@synthesize uuid;

+ (instancetype _Nullable) eventWithType:(NSString* _Nonnull) eventType happenedAt:(NSDate* _Nonnull) happenedAt andProperties:(NSDictionary* _Nullable) properties forEntity:(NSEntityDescription*) entity {
    KSEventModel* event = [[KSEventModel alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];

    if (!event) {
        return nil;
    }

    NSNumber* happenedAtMillis = [NSNumber numberWithDouble:[happenedAt timeIntervalSince1970] * 1000];
    NSString* uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
    NSData* propsJson = nil;
    NSError* err = nil;
    
    if (properties) {
        propsJson = [NSJSONSerialization dataWithJSONObject:properties options:0 error:&err];
        
        if (err) {
            NSLog(@"Failed to encode properties, properties will be nil");
            propsJson = nil;
            err = nil;
        }
    }
    
    event.uuid = uuid;
    event.eventType = eventType;
    event.happenedAt = happenedAtMillis;
    event.properties = propsJson;

    return event;
}

- (NSDictionary* _Nonnull) asDict {
    NSError* err = nil;
    id propsObject = nil;
    
    if (self.properties) {
        propsObject = [NSJSONSerialization JSONObjectWithData:self.properties options:0 error:&err];
        if (err) {
            NSLog(@"Failed to decode event properties: %@", err);
        }
    }
    
    return @{
             @"type": self.eventType,
             @"uuid": self.uuid,
             @"timestamp": self.happenedAt,
             @"data": (propsObject) ? propsObject : [NSNull null]
             };
}
    
@end

@implementation AnalyticsHelper

#pragma mark - Initialization

- (instancetype _Nullable) initWithKumulos:(Kumulos *)kumulos {
    if (self = [super init]) {
        self.kumulos = kumulos;
        self.startNewSession = YES;
        self.sessionIdleTimer = nil;
        self.bgTask = UIBackgroundTaskInvalid;
        
        [self initContext];
        [self registerListeners];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self syncEvents];
        });
    }
    
    return self;
}

- (void) initContext {
    NSManagedObjectModel* objectModel = [self getDataModel];
    
    if (!objectModel) {
        NSLog(@"Failed to create object model");
        return;
    }
    
    NSPersistentStoreCoordinator* storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:objectModel];
    
    NSURL* docsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* storeUrl = [NSURL URLWithString:@"KAnalyticsDb.sqlite" relativeToURL:docsUrl];
    
    NSDictionary* options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};

    NSError* err = nil;
    [storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&err];
    
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
    [self trackEvent:eventType atTime:[NSDate date] withProperties:properties];
}

- (void) trackEvent:(NSString *)eventType withProperties:(NSDictionary *)properties flushingImmediately:(BOOL)flushImmediately {
    [self trackEvent:eventType atTime:[NSDate date] withProperties:properties asynchronously:YES flushingImmediately:flushImmediately];
}

- (void) trackEvent:(NSString *)eventType atTime:(NSDate *)happenedAt withProperties:(NSDictionary *)properties {
    [self trackEvent:eventType atTime:happenedAt withProperties:properties asynchronously:YES];
}

- (void) trackEvent:(NSString *)eventType atTime:(NSDate *)happenedAt withProperties:(NSDictionary *)properties asynchronously:(BOOL)asynchronously {
    [self trackEvent:eventType atTime:happenedAt withProperties:properties asynchronously:YES flushingImmediately:NO];
}

- (void) trackEvent:(NSString *)eventType atTime:(NSDate *)happenedAt withProperties:(NSDictionary *)properties asynchronously:(BOOL)asynchronously flushingImmediately:(BOOL)flushImmediately {
    if ([eventType isEqualToString:@""] || (properties && ![NSJSONSerialization isValidJSONObject:properties])) {
        NSLog(@"Ignoring invalid event with empty type or non-serializable properties");
        return;
    }
    
    void (^workItem)(void) = ^{
        NSManagedObjectContext* context = self.analyticsContext;
        
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
        
        if (!entity) {
            return;
        }
        
        KSEventModel* event = [KSEventModel
                               eventWithType:eventType
                               happenedAt:happenedAt
                               andProperties:properties
                               forEntity:entity];

        if (!event) {
            return;
        }
        
        NSError* err = nil;
        
        [context insertObject:event];
        [context save:&err];
        
        if (err) {
            NSLog(@"Failed to record event: %@", err);
            return;
        }
        
        if (flushImmediately) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self syncEvents];
            });
        }
    };
    
    if (asynchronously) {
        [self.analyticsContext performBlock:workItem];
    }
    else {
        [self.analyticsContext performBlockAndWait:workItem];
    }
}

- (void) syncEvents {
    NSArray<KSEventModel*>* results = [self fetchEventsBatch];
    
    if (results.count) {
        [self syncEventsBatch:results];
    }
    else if (self.bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
}

- (void) syncEventsBatch:(NSArray<KSEventModel*>*) events {
    NSMutableArray* data = [[NSMutableArray alloc] initWithCapacity:events.count];
    
    for (KSEventModel* event in events) {
        [data addObject:[event asDict]];
    }
    
    NSString* path = [NSString stringWithFormat:@"/v1/app-installs/%@/events", [Kumulos installId]];
    [self.kumulos.eventsHttpClient post:path data:data onSuccess:^(NSHTTPURLResponse * _Nullable response, id  _Nullable decodedBody) {
        NSError* err = [self pruneEventsBatch:events];
        
        if (err) {
            NSLog(@"Failed to prune events: %@", err);
            return;
        }
        
        [self syncEvents];
    } onFailure:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        // Failed so assume will be retried some other time
        if (self.bgTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
            self.bgTask = UIBackgroundTaskInvalid;
        }
    }];
}

- (NSError*) pruneEventsBatch:(NSArray<KSEventModel*>*) events {
    NSError* err = nil;

    for (KSEventModel* event in events) {
        [self.analyticsContext deleteObject:event];
    }
    
    [self.analyticsContext save:&err];
    
    return err;
}

- (NSArray<KSEventModel*>* _Nonnull) fetchEventsBatch {
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Event"];
    request.returnsObjectsAsFaults = NO;
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"happenedAt" ascending:YES] ];
    request.fetchLimit = 100;
    request.includesPendingChanges = NO;
    
    NSError* err = nil;
    
    NSArray<KSEventModel*>* results = [self.analyticsContext executeFetchRequest:request error:&err];
    
    if (err) {
        NSLog(@"Failed to fetch events batch: %@", err);
        results = @[];
    }
    
    return results;
}

#pragma mark - App lifecycle delegates

- (void) appBecameActive {
    if (self.startNewSession) {
        [self trackEvent:KumulosEventForeground withProperties:nil];
        self.startNewSession = NO;
        return;
    }
    
    if (self.sessionIdleTimer) {
        [self.sessionIdleTimer invalidate];
        self.sessionIdleTimer = nil;
    }
    
    if (self.bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
}

- (void) appBecameInactive {
    self.becameInactiveAt = [NSDate date];
    
    NSUInteger timeout = self.kumulos.config.sessionIdleTimeoutSeconds;
    self.sessionIdleTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(sessionDidEnd) userInfo:nil repeats:NO];
}

- (void) appBecameBackground {
    self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"sync" expirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void) appWillTerminate {
    if (self.sessionIdleTimer) {
        [self.sessionIdleTimer invalidate];
        [self sessionDidEnd];
    }
}

- (void) sessionDidEnd {
    self.startNewSession = YES;
    self.sessionIdleTimer = nil;

    [self trackEvent:KumulosEventBackground atTime:self.becameInactiveAt withProperties:nil asynchronously:NO];
    self.becameInactiveAt = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self syncEvents];
    });
}

#pragma mark - CoreData model definition

- (NSManagedObjectModel*) getDataModel {
    NSManagedObjectModel* model = [NSManagedObjectModel new];
    
    if (!model) {
        return nil;
    }
    
    NSEntityDescription* eventEntity = [NSEntityDescription new];
    eventEntity.name = @"Event";
    eventEntity.managedObjectClassName = NSStringFromClass(KSEventModel.class);
    
    NSMutableArray<NSAttributeDescription*>* eventProps = [NSMutableArray array];
    
    NSAttributeDescription* eventTypeProp = [NSAttributeDescription new];
    eventTypeProp.name = @"eventType";
    eventTypeProp.attributeType = NSStringAttributeType;
    eventTypeProp.optional = NO;
    [eventProps addObject:eventTypeProp];
    
    NSAttributeDescription* happenedAtProp = [NSAttributeDescription new];
    happenedAtProp.name = @"happenedAt";
    happenedAtProp.attributeType = NSInteger64AttributeType;
    happenedAtProp.optional = NO;
    happenedAtProp.defaultValue = @(0);
    [eventProps addObject:happenedAtProp];
    
    NSAttributeDescription* propertiesProp = [NSAttributeDescription new];
    propertiesProp.name = @"properties";
    propertiesProp.attributeType = NSBinaryDataAttributeType;
    propertiesProp.optional = YES;
    [eventProps addObject:propertiesProp];
    
    NSAttributeDescription* uuidProp = [NSAttributeDescription new];
    uuidProp.name = @"uuid";
    uuidProp.attributeType = NSStringAttributeType;
    uuidProp.optional = NO;
    [eventProps addObject:uuidProp];
    
    [eventEntity setProperties:eventProps];
    [model setEntities:@[eventEntity]];
    
    return model;
}

@end
