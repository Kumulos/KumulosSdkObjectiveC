//
//  KSAnalyticsHelper.m
//  KumulosSDK iOS
//

#import "KSAnalyticsHelper.h"
#import "../Kumulos+Protected.h"
#import "../Kumulos+Analytics.h"
#import "../KumulosEvents.h"
#import "KumulosHelper.h"
#import "KSAppGroupsHelper.h"

@interface KSAnalyticsHelper ()

@property NSManagedObjectContext* analyticsContext;
@property NSManagedObjectContext* migrationAnalyticsContext;
@property (nonatomic) KSHttpClient* _Nullable eventsHttpClient;

@end

static NSString * const KSEventsBaseUrl = @"https://events.kumulos.com";

@implementation KSEventModel : NSManagedObject

@dynamic eventType;
@dynamic happenedAt;
@dynamic properties;
@dynamic uuid;
@dynamic userIdentifier;

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
    event.userIdentifier = KumulosHelper.currentUserIdentifier;
    
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
        @"data": (propsObject) ? propsObject : NSNull.null,
        @"userId": (self.userIdentifier) ? self.userIdentifier : NSNull.null
    };
}

@end

@implementation KSAnalyticsHelper

#pragma mark - Initialization

- (instancetype _Nullable) initWithApiKey:(NSString*)apiKey withSecretKey:(NSString*)secretKey {
    if (self = [super init]) {
        self.eventsHttpClient = [[KSHttpClient alloc] initWithBaseUrl:KSEventsBaseUrl requestBodyFormat:KSHttpDataFormatJson responseBodyFormat:KSHttpDataFormatJson];
        [self.eventsHttpClient setBasicAuthWithUser:apiKey andPassword:secretKey];
        
        [self initContext];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (self.migrationAnalyticsContext != nil){
                [self syncEvents:self.migrationAnalyticsContext onSyncComplete: nil];
            }
            [self syncEvents:self.analyticsContext onSyncComplete:nil];
        });
    }
    
    return self;
}

- (void) dealloc {
    [self.eventsHttpClient invalidateSessionCancelingTasks:NO];
    self.eventsHttpClient = nil;
}

- (NSURL*) getMainStoreUrl:(BOOL)appGroupExists {
    if (!appGroupExists){
        return [self getAppDbUrl];
    }
    
    return [self getSharedDbUrl];
}

- (NSURL*) getAppDbUrl {
    NSURL* docsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* appDbUrl = [NSURL URLWithString:@"KAnalyticsDb.sqlite" relativeToURL:docsUrl];
    
    return appDbUrl;
}

- (NSURL*) getSharedDbUrl {
    NSURL* sharedContainerPath = [KSAppGroupsHelper getSharedContainerPath];
    if (sharedContainerPath == nil){
        return nil;
    }
    
    return [NSURL URLWithString:@"KAnalyticsDbShared.sqlite" relativeToURL:sharedContainerPath];
}

- (void) initContext {
    NSURL* appDbUrl = [self getAppDbUrl];
    BOOL appDbExists = appDbUrl == nil ? NO : [[NSFileManager defaultManager] fileExistsAtPath:appDbUrl.path];
    BOOL appGroupExists = [KSAppGroupsHelper isKumulosAppGroupDefined];
    
    NSURL* storeUrl = [self getMainStoreUrl:appGroupExists];
    if (appGroupExists && appDbExists){
        self.migrationAnalyticsContext = [self getManagedObjectContext:appDbUrl];
    }
    
    self.analyticsContext = [self getManagedObjectContext:storeUrl];
}

- (NSManagedObjectContext*) getManagedObjectContext:(NSURL*) storeUrl {
    NSManagedObjectModel* objectModel = [self getDataModel];
    if (!objectModel) {
        NSLog(@"Failed to create object model");
        return nil;
    }
    
    NSPersistentStoreCoordinator* storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:objectModel];
    NSDictionary* options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
    NSError* err = nil;
    [storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&err];
    
    if (err) {
        NSLog(@"Failed to set up persistent store: %@", err);
        return nil;
    }
    
    NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context performBlockAndWait:^{
        context.persistentStoreCoordinator = storeCoordinator;
    }];
    
    return context;
}

# pragma mark - Event tracking

- (void) trackEvent:(NSString *)eventType withProperties:(NSDictionary *)properties {
    [self trackEvent:eventType atTime:[NSDate date] withProperties:properties flushingImmediately:NO onSyncComplete:nil];
}

- (void) trackEvent:(NSString *)eventType withProperties:(NSDictionary *)properties flushingImmediately:(BOOL)flushImmediately {
    [self trackEvent:eventType atTime:[NSDate date] withProperties:properties flushingImmediately:flushImmediately onSyncComplete: nil];
}

- (void) trackEvent:(NSString *)eventType
             atTime:(NSDate *)happenedAt
     withProperties:(NSDictionary *)properties
flushingImmediately:(BOOL)flushImmediately
     onSyncComplete:(SyncCompletedBlock)onSyncComplete
{
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
                [self syncEvents:self.analyticsContext onSyncComplete: onSyncComplete];
            });
        }
    };
    
    [self.analyticsContext performBlock:workItem];
}

- (void) syncEvents:(NSManagedObjectContext*)context onSyncComplete:(SyncCompletedBlock)onSyncComplete {
    [context performBlockAndWait:^{
        NSArray<KSEventModel*>* results = [self fetchEventsBatch:context];
        
        if (results.count == 0){
            if (onSyncComplete){
                onSyncComplete(nil);
            }
            
            if (context == self.migrationAnalyticsContext){
                [self removeAppDatabase];
            }
            
        }
        else if (results.count > 0){
            [self syncEventsBatch:context events:results onSyncComplete: onSyncComplete];
        }
    }];
}

- (void) removeAppDatabase {
    if (self.migrationAnalyticsContext == nil){
        return;
    }
    
    NSPersistentStoreCoordinator* persStoreCoord = self.migrationAnalyticsContext.persistentStoreCoordinator;
    if (persStoreCoord == nil){
        return;
    }
    
    NSPersistentStore* store = persStoreCoord.persistentStores.lastObject;
    if (store == nil){
        return;
    }
    
    NSURL* storeUrl = [persStoreCoord URLForPersistentStore:store];
    [self.migrationAnalyticsContext performBlockAndWait:^{
        [self.migrationAnalyticsContext reset];
        
        NSError* err = nil;
        [persStoreCoord removePersistentStore:store error:&err];
        [[NSFileManager defaultManager] removeItemAtURL:storeUrl error:&err];
    }];
    
    self.migrationAnalyticsContext = nil;
}

- (void) syncEventsBatch:(NSManagedObjectContext*)context events:(NSArray<KSEventModel*>*)events onSyncComplete:(SyncCompletedBlock)onSyncComplete {
    NSMutableArray* data = [NSMutableArray arrayWithCapacity:events.count];
    NSMutableArray<NSManagedObjectID*>* eventIds = [NSMutableArray arrayWithCapacity:events.count];
    
    for (KSEventModel* event in events) {
        [data addObject:[event asDict]];
        [eventIds addObject:event.objectID];
    }
    
    NSString* path = [NSString stringWithFormat:@"/v1/app-installs/%@/events", [KumulosHelper installId]];
    
    [self.eventsHttpClient post:path data:data onSuccess:^(NSHTTPURLResponse * _Nullable response, id  _Nullable decodedBody) {
        NSError* err = [self pruneEventsBatch:context eventIds:eventIds];
        
        if (err) {
            NSLog(@"Failed to prune events: %@", err);
            return;
        }
        
        [self syncEvents:context onSyncComplete:onSyncComplete];
    } onFailure:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"Failed to send events");
        if (onSyncComplete){
            onSyncComplete(error);
        }
    }];
}

- (NSError*) pruneEventsBatch:(NSManagedObjectContext*)context eventIds:(NSArray<NSManagedObjectID*>*) eventIds {
    __block NSError* err = nil;
    
    [context performBlockAndWait:^{
        for (NSManagedObjectID* eventId in eventIds) {
            KSEventModel* event = [context objectWithID:eventId];
            [context deleteObject:event];
        }
        
        [context save:&err];
    }];
    
    return err;
}

- (NSArray<KSEventModel*>* _Nonnull) fetchEventsBatch:(NSManagedObjectContext*)context {
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Event"];
    request.returnsObjectsAsFaults = NO;
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"happenedAt" ascending:YES] ];
    request.fetchLimit = 100;
    request.includesPendingChanges = NO;
    
    NSError* err = nil;
    
    NSArray<KSEventModel*>* results = [context executeFetchRequest:request error:&err];
    
    if (err) {
        NSLog(@"Failed to fetch events batch: %@", err);
        results = @[];
    }
    
    return results;
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
    
    NSAttributeDescription* userIdProp = [NSAttributeDescription new];
    userIdProp.name = @"userIdentifier";
    userIdProp.attributeType = NSStringAttributeType;
    userIdProp.optional = YES;
    [eventProps addObject:userIdProp];
    
    [eventEntity setProperties:eventProps];
    [model setEntities:@[eventEntity]];
    
    return model;
}

@end
