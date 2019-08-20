//
//  KSInAppHelper.m
//  KumulosSDK
//

#import <objc/runtime.h>
#import "KSInAppHelper.h"
#import "../Kumulos+Analytics.h"
#import "../Kumulos+Protected.h"
#import "../KumulosEvents.h"
#import "../Http/NSString+URLEncoding.h"
#import "KSInAppPresenter.h"

#define KUMULOS_MESSAGES_LAST_SYNC_TIME @"KumulosMessagesLastSyncTime"
#define KUMULOS_IN_APP_CONSENTED_FOR_USER @"KumulosInAppConsentedForUser"
NSUInteger const KS_MESSAGE_TYPE_IN_APP = 2;

NSString* _Nonnull const KSInAppPresentedImmediately = @"immediately";
NSString* _Nonnull const KSInAppPresentedNextOpen = @"next-open";
NSString* _Nonnull const KSInAppPresentedFromInbox = @"never";

static IMP ks_existingBackgroundFetchDelegate = NULL;

typedef void (^KSCompletionHandler)(UIBackgroundFetchResult);
void kumulos_applicationPerformFetchWithCompletionHandler(id self, SEL _cmd, UIApplication* application, KSCompletionHandler completionHandler);

@interface KSInAppHelper ()

@property (nonatomic) Kumulos* _Nonnull kumulos;
@property (nonatomic) KSInAppPresenter* _Nonnull presenter;
@property (nonatomic) NSManagedObjectContext* messagesContext;
@property (nonatomic) NSMutableArray<NSNumber*>* pendingTickleIds;

@end

@implementation KSInAppHelper

#pragma mark - Initialization

- (instancetype)initWithKumulos:(Kumulos* _Nonnull)kumulos {
    if (self = [super init]) {
        self.kumulos = kumulos;
        self.pendingTickleIds = [[NSMutableArray alloc] initWithCapacity:1];
        self.presenter = [[KSInAppPresenter alloc] initWithKumulos:kumulos];
        [self initContext];
        [self handleAutoEnrollmentAndSyncSetup];
    }

    return self;
}

- (void)initContext {
    NSManagedObjectModel* objectModel = [self getDataModel];

    if (!objectModel) {
        NSLog(@"Failed to create object model");
        return;
    }

    NSPersistentStoreCoordinator* storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:objectModel];

    NSURL* docsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* storeUrl = [NSURL URLWithString:@"KSMessagesDb.sqlite" relativeToURL:docsUrl];

    NSDictionary* options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};

    NSError* err = nil;
    [storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&err];

    if (err) {
        NSLog(@"Failed to set up persistent store: %@", err);
        return;
    }

    self.messagesContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [self.messagesContext performBlockAndWait:^{
        self.messagesContext.persistentStoreCoordinator = storeCoordinator;
    }];
}

- (void) appBecameActive {
    @synchronized (self.pendingTickleIds) {
        NSArray<KSInAppMessage*>* messagesToPresent = [self getMessagesToPresent:@[KSInAppPresentedImmediately, KSInAppPresentedNextOpen]];
        [self.presenter queueMessagesForPresentation:messagesToPresent presentingTickles:self.pendingTickleIds];
    }
}

- (void) setupSyncTask {
    // TODO iOS13 background task service (later)
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = UIApplication.sharedApplication.delegate.class;

        // Perform background fetch
        SEL performFetchSelector = @selector(application:performFetchWithCompletionHandler:);
        const char *fetchType = [[NSString stringWithFormat:@"%s%s%s%s%s", @encode(void), @encode(id), @encode(SEL), @encode(UIApplication*), @encode(KSCompletionHandler)] UTF8String];

        ks_existingBackgroundFetchDelegate = class_replaceMethod(class, performFetchSelector, (IMP)kumulos_applicationPerformFetchWithCompletionHandler, fetchType);
    });
}

#pragma mark - State helpers

-(NSString*) keyForUserConsent {
    return KUMULOS_IN_APP_CONSENTED_FOR_USER;
}

-(BOOL)inAppEnabled {
    BOOL enabled = self.kumulos.config.inAppConsentStrategy == KSInAppConsentStrategyExplicitByUser || self.kumulos.config.inAppConsentStrategy == KSInAppConsentStrategyAutoEnroll;

    return enabled && [self userConsented];
}

-(BOOL)userConsented {
    NSNumber* userConsentedPref = [NSUserDefaults.standardUserDefaults objectForKey:[self keyForUserConsent]];
    BOOL userConsented = userConsentedPref != nil ? [userConsentedPref boolValue] : NO;
    return userConsented;
}

-(void)updateUserConsent:(BOOL)consentGiven {
    NSDictionary* props = @{@"consented": @(consentGiven)};
    [self.kumulos trackEventImmediately:KumulosEventInAppConsentChanged withProperties:props];

    NSString* consentKey = [self keyForUserConsent];

    if (consentGiven) {
        [NSUserDefaults.standardUserDefaults setObject:@(consentGiven) forKey:consentKey];
        [self handleAutoEnrollmentAndSyncSetup];
    } else {
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:consentKey];
    }
}

-(void) handleAutoEnrollmentAndSyncSetup {
    if (self.kumulos.config.inAppConsentStrategy == KSInAppConsentStrategyAutoEnroll && [self userConsented] == NO) {
        [self updateUserConsent:YES];
        return;
    }

    if ([self inAppEnabled]) {
        [self setupSyncTask];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(appBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}


#pragma mark - Message management

-(void)sync:(void (^_Nullable)(int result))onComplete {
    NSDate* lastSyncTime = [NSUserDefaults.standardUserDefaults objectForKey:KUMULOS_MESSAGES_LAST_SYNC_TIME];
    NSString* after = @"";

    if (lastSyncTime != nil) {
        NSDateFormatter* formatter = [NSDateFormatter new];
        [formatter setTimeStyle:NSDateFormatterFullStyle];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        after = [NSString stringWithFormat:@"?after=%@", [[formatter stringFromDate:lastSyncTime] urlEncodedString]];
    }

    NSString* path = [NSString stringWithFormat:@"/v1/users/%@/messages%@", Kumulos.currentUserIdentifier, after];

    [self.kumulos.pushHttpClient get:path onSuccess:^(NSHTTPURLResponse * _Nullable response, id  _Nullable decodedBody) {
        NSArray<NSDictionary*>* messagesToPersist = decodedBody;
        if (!messagesToPersist.count) {
            if (onComplete) {
                onComplete(0);
            }
            return;
        }

        [self persistInAppMessages:messagesToPersist];

        if (onComplete) {
            onComplete(1);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
                return;
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSArray<KSInAppMessage*>* messagesToPresent = [self getMessagesToPresent:@[KSInAppPresentedImmediately]];
                [self.presenter queueMessagesForPresentation:messagesToPresent presentingTickles:self.pendingTickleIds];
            });
        });
    } onFailure:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (onComplete) {
            onComplete(-1);
        }
    }];
}

-(void)persistInAppMessages:(NSArray<NSDictionary*>*)messages {
    [self.messagesContext performBlockAndWait:^{
        NSManagedObjectContext* context = self.messagesContext;
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:context];

        if (!entity) {
            NSLog(@"Failed to get entity description for Message, aborting!");
            return;
        }

        NSDate* lastSyncTime = [NSDate dateWithTimeIntervalSince1970:0];
        NSDateFormatter* dateParser = [NSDateFormatter new];
        [dateParser setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

        for (NSDictionary* message in messages) {
            NSNumber* partId = message[@"id"];

            NSFetchRequest* fetchRequest = [NSFetchRequest new];
            [fetchRequest setEntity:entity];
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"id = %@", partId];
            [fetchRequest setPredicate:predicate];
            NSArray<KSInAppMessageEntity*>* fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];

            // Upsert
            KSInAppMessageEntity* model = fetchedObjects.count == 1 ? fetchedObjects[0] : [[KSInAppMessageEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:context];

            model.id = partId;
            model.updatedAt = [dateParser dateFromString:message[@"updatedAt"]];
            model.openedAt = [message[@"openedAt"] isEqual:NSNull.null] ? nil : [dateParser dateFromString:message[@"openedAt"]];
            model.presentedWhen = message[@"presentedWhen"];
            model.content = message[@"content"];
            model.data = message[@"data"];
            model.badgeConfig = message[@"badge"];
            model.inboxConfig = [message[@"inbox"] isEqual:NSNull.null] ? nil : message[@"inbox"];

            if (model.inboxConfig != nil) {
                NSDictionary* inbox = model.inboxConfig;
                model.inboxFrom = ![inbox[@"from"] isEqual:NSNull.null] ? [dateParser dateFromString:inbox[@"from"]] : nil;
                model.inboxTo = ![inbox[@"to"] isEqual:NSNull.null] ? [dateParser dateFromString:inbox[@"to"]] : nil;
            }

            if ([model.updatedAt timeIntervalSince1970] > [lastSyncTime timeIntervalSince1970]) {
                lastSyncTime = model.updatedAt;
            }
        }

        // Evict
        [self evictMessages:context];

        NSError* err = nil;
        [context save:&err];

        if (err != nil) {
            NSLog(@"Failed to persist messages");
            NSLog(@"%@", err);
            return;
        }

        [NSUserDefaults.standardUserDefaults setObject:lastSyncTime forKey:KUMULOS_MESSAGES_LAST_SYNC_TIME];
    }];
}

- (void) evictMessages:(NSManagedObjectContext* _Nonnull)context {
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    [fetchRequest setIncludesPendingChanges:YES];

    NSPredicate* predicate = [NSPredicate
                              predicateWithFormat:@"(openedAt != %@ AND inboxConfig = %@) OR (inboxTo != %@ AND inboxTo < %@)",
                              nil, nil, nil, [NSDate date]];
    [fetchRequest setPredicate:predicate];

    NSError* err = nil;
    NSArray<KSInAppMessageEntity*>* toEvict = [context executeFetchRequest:fetchRequest error:&err];

    if (err != nil) {
        NSLog(@"Failed to evict messages %@", err);
        return;
    }

    for (KSInAppMessageEntity* message in toEvict) {
        [context deleteObject:message];
    }
}

-(NSArray<KSInAppMessage*>*) getMessagesToPresent:(NSArray<NSString*>*)presentedWhenOptions {
    NSArray<KSInAppMessage*>* __block messages = @[];

    [self.messagesContext performBlockAndWait:^{
        NSManagedObjectContext* context = self.messagesContext;
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:context];

        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        [fetchRequest setEntity:entity];
        [fetchRequest setIncludesPendingChanges:NO];
        [fetchRequest setReturnsObjectsAsFaults:NO];
        NSPredicate* predicate = [NSPredicate
                                  predicateWithFormat:@"((presentedWhen IN %@) OR (id IN %@)) AND (openedAt = %@)",
                                  presentedWhenOptions,
                                  self.pendingTickleIds,
                                  nil];

        [fetchRequest setPredicate:predicate];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updatedAt"
                                                                       ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

        NSError *err = nil;
        NSArray *entities = [context executeFetchRequest:fetchRequest error:&err];
        if (err != nil) {
            NSLog(@"Failed to fetch: %@", err);
            return;
        }

        if (!entities.count) {
            return;
        }

        messages = [self mapEntitiesToModels:entities];
    }];

    return messages;
}

- (void)markMessageOpened:(KSInAppMessage *)message {
    [self.kumulos trackEvent:KumulosEventMessageOpened withProperties:@{@"type": @(KS_MESSAGE_TYPE_IN_APP), @"id": message.id}];
    [self.messagesContext performBlock:^{
        NSManagedObjectContext* context = self.messagesContext;
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:context];

        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        [fetchRequest setEntity:entity];
        [fetchRequest setIncludesPendingChanges:NO];
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"id = %@", message.id];
        [fetchRequest setPredicate:predicate];

        NSError* err = nil;
        NSArray<KSInAppMessageEntity*>* messageEntities = [context executeFetchRequest:fetchRequest error:&err];

        if (err == nil && messageEntities != nil && messageEntities.count == 1) {
            messageEntities[0].openedAt = [NSDate date];

            [context save:&err];

            if (err != nil) {
                NSLog(@"Failed to update message: %@", err);
            }
        }
    }];
}

#pragma mark - Interop with other components

- (void)handleAssociatedUserChange {
    if (![self inAppEnabled]) {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.messagesContext performBlockAndWait:^{
            NSManagedObjectContext* context = self.messagesContext;
            NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
            [fetchRequest setIncludesPendingChanges:YES];

            NSError* err = nil;
            NSArray<KSInAppMessageEntity*>* messages = [context executeFetchRequest:fetchRequest error:&err];

            if (err != nil) {
                return;
            }

            for (KSInAppMessageEntity* message in messages) {
                [context deleteObject:message];
            }

            [context save:&err];

            if (err != nil) {
                NSLog(@"Failed to clean up messages: %@", err);
                return;
            }
        }];

        [NSUserDefaults.standardUserDefaults removeObjectForKey:[self keyForUserConsent]];
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [self handleAutoEnrollmentAndSyncSetup];
    });
}

- (void) handlePushOpen:(KSPushNotification *)notification {
    if (![self inAppEnabled] || !notification.inAppDeepLink) {
        return;
    }

    BOOL isActive = UIApplication.sharedApplication.applicationState == UIApplicationStateActive;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSNumber* inAppPartId = notification.inAppDeepLink[@"data"][@"id"];
        @synchronized (self.pendingTickleIds) {
            [self.pendingTickleIds addObject:inAppPartId];
            if (isActive) {
                NSArray<KSInAppMessage*>* messages = [self getMessagesToPresent:@[]];
                [self.presenter queueMessagesForPresentation:messages presentingTickles:self.pendingTickleIds];
            }
        }
    });
}

#pragma mark - Data model

- (NSArray<KSInAppMessage*>*) mapEntitiesToModels:(NSArray<KSInAppMessageEntity*>*)entities {
    if (nil == entities || !entities.count) {
        return @[];
    }

    NSMutableArray<KSInAppMessage*>* models = [[NSMutableArray alloc] initWithCapacity:entities.count];
    for (KSInAppMessageEntity* entity in entities) {
        KSInAppMessage* model = [KSInAppMessage fromEntity:entity];
        [models addObject:model];
    }

    return models;
}

- (NSManagedObjectModel*)getDataModel {
    NSManagedObjectModel* model = [NSManagedObjectModel new];

    if (!model) {
        return nil;
    }

    NSEntityDescription* messageEntity = [NSEntityDescription new];
    messageEntity.name = @"Message";
    messageEntity.managedObjectClassName = NSStringFromClass(KSInAppMessageEntity.class);

    NSMutableArray<NSAttributeDescription*>* messageProps = [NSMutableArray arrayWithCapacity:10];

    NSAttributeDescription* partId = [NSAttributeDescription new];
    partId.name = @"id";
    partId.attributeType = NSInteger64AttributeType;
    partId.optional = NO;
    [messageProps addObject:partId];

    NSAttributeDescription* updatedAt = [NSAttributeDescription new];
    updatedAt.name = @"updatedAt";
    updatedAt.attributeType = NSDateAttributeType;
    updatedAt.optional = NO;
    [messageProps addObject:updatedAt];

    NSAttributeDescription* presentedWhen = [NSAttributeDescription new];
    presentedWhen.name = @"presentedWhen";
    presentedWhen.attributeType = NSStringAttributeType;
    presentedWhen.optional = NO;
    [messageProps addObject:presentedWhen];

    NSAttributeDescription* content = [NSAttributeDescription new];
    content.name = @"content";
    content.attributeType = NSTransformableAttributeType;
    content.valueTransformerName = NSStringFromClass(KSJsonValueTransformer.class);
    content.optional = NO;
    [messageProps addObject:content];

    NSAttributeDescription* data = [NSAttributeDescription new];
    data.name = @"data";
    data.attributeType = NSTransformableAttributeType;
    data.valueTransformerName = NSStringFromClass(KSJsonValueTransformer.class);
    data.optional = YES;
    [messageProps addObject:data];

    NSAttributeDescription* badgeConfig = [NSAttributeDescription new];
    badgeConfig.name = @"badgeConfig";
    badgeConfig.attributeType = NSTransformableAttributeType;
    badgeConfig.valueTransformerName = NSStringFromClass(KSJsonValueTransformer.class);
    badgeConfig.optional = YES;
    [messageProps addObject:badgeConfig];

    NSAttributeDescription* inboxConfig = [NSAttributeDescription new];
    inboxConfig.name = @"inboxConfig";
    inboxConfig.attributeType = NSTransformableAttributeType;
    inboxConfig.valueTransformerName = NSStringFromClass(KSJsonValueTransformer.class);
    inboxConfig.optional = YES;
    [messageProps addObject:inboxConfig];

    NSAttributeDescription* inboxFrom = [NSAttributeDescription new];
    inboxFrom.name = @"inboxFrom";
    inboxFrom.attributeType = NSDateAttributeType;
    inboxFrom.optional = YES;
    [messageProps addObject:inboxFrom];

    NSAttributeDescription* inboxTo = [NSAttributeDescription new];
    inboxTo.name = @"inboxTo";
    inboxTo.attributeType = NSDateAttributeType;
    inboxTo.optional = YES;
    [messageProps addObject:inboxTo];

    NSAttributeDescription* openedAt = [NSAttributeDescription new];
    openedAt.name = @"openedAt";
    openedAt.attributeType = NSDateAttributeType;
    openedAt.optional = YES;
    [messageProps addObject:openedAt];

    [messageEntity setProperties:messageProps];
    [model setEntities:@[messageEntity]];

    return model;
}

@end

@implementation KSJsonValueTransformer

+ (Class)transformedValueClass {
    return NSData.class;
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if (value == nil || [value isEqual:NSNull.null]) {
        return nil;
    }

    if (![NSJSONSerialization isValidJSONObject:value]) {
        NSLog(@"Object cannot be transformed to JSON data object!");
        return nil;
    }

    NSError* err = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:value options:0 error:&err];

    if (err != nil) {
        NSLog(@"Failed to transform JSON to data object");
    }

    return data;
}

- (id)reverseTransformedValue:(id)value {
    NSError* err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:value options:0 error:&err];

    if (err != nil) {
        NSLog(@"Failed to transform data to JSON object");
    }

    return obj;
}

@end

#pragma mark - Swizzled behaviour handlers

void kumulos_applicationPerformFetchWithCompletionHandler(id self, SEL _cmd, UIApplication* application, KSCompletionHandler completionHandler) {
    UIBackgroundFetchResult __block fetchResult = UIBackgroundFetchResultNoData;
    dispatch_semaphore_t __block fetchBarrier = dispatch_semaphore_create(0);

    if (ks_existingBackgroundFetchDelegate) {
        ((void(*)(id,SEL,UIApplication*,KSCompletionHandler))ks_existingBackgroundFetchDelegate)(self, _cmd, application, ^(UIBackgroundFetchResult result) {
            fetchResult = result;
            dispatch_semaphore_signal(fetchBarrier);
        });
    } else {
        dispatch_semaphore_signal(fetchBarrier);
    }

    if ([Kumulos.shared.inAppHelper inAppEnabled]) {
        [Kumulos.shared.inAppHelper sync:^(int result) {
            dispatch_semaphore_wait(fetchBarrier, dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC));

            if (result < 0) {
                fetchResult = UIBackgroundFetchResultFailed;
            } else if (result > 1) {
                fetchResult = UIBackgroundFetchResultNewData;
            }
            // No data case is default, allow override from other handler

            completionHandler(fetchResult);
        }];
    } else {
        completionHandler(fetchResult);
    }
}
