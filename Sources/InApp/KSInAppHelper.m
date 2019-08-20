//
//  KSInAppHelper.m
//  KumulosSDK
//

#import "KSInAppHelper.h"
#import "../Kumulos+Analytics.h"
#import "../Kumulos+Protected.h"
#import "../KumulosEvents.h"
#import "../Http/NSString+URLEncoding.h"

#define KUMULOS_MESSAGES_LAST_SYNC_TIME @"KumulosMessagesLastSyncTime"
#define KUMULOS_IN_APP_CONSENTED_FOR_USER @"KumulosInAppConsentedForUser"

@interface KSInAppHelper ()

@property (nonatomic) Kumulos* _Nonnull kumulos;
@property NSManagedObjectContext* messagesContext;

@end

@implementation KSInAppHelper

#pragma mark - Initialization

- (instancetype)initWithKumulos:(id)kumulos {
    if (self = [super init]) {
        self.kumulos = kumulos;
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

#pragma mark - State helpers

-(NSString*) keyForUserConsent {
    NSString* key = [NSString stringWithFormat:@"%@:%@", KUMULOS_IN_APP_CONSENTED_FOR_USER, Kumulos.currentUserIdentifier];
    return key;
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
        // TODO start sync etc.
        [NSUserDefaults.standardUserDefaults setObject:@(consentGiven) forKey:consentKey];
        [self handleAutoEnrollmentAndSyncSetup];
    } else {
        // TODO stop sync, reset flags etc.
        [NSUserDefaults.standardUserDefaults removeObjectForKey:consentKey];
    }
}

-(void) handleAutoEnrollmentAndSyncSetup {
    if (self.kumulos.config.inAppConsentStrategy == KSInAppConsentStrategyAutoEnroll && [self userConsented] == NO) {
        [self updateUserConsent:YES];
        return;
    }

    if ([self inAppEnabled]) {
        [self sync];
        // TODO swizzle fetch handler (now)
        // TODO iOS13 background task service (later)
    }
}


#pragma mark - Message stuff

-(void)sync {
    NSDate* lastSyncTime = [NSUserDefaults.standardUserDefaults objectForKey:KUMULOS_MESSAGES_LAST_SYNC_TIME];
    NSString* after = @"";

    if (lastSyncTime != nil) {
        NSDateFormatter* formatter = [NSDateFormatter new];
        [formatter setTimeStyle:NSDateFormatterFullStyle];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        after = [NSString stringWithFormat:@"?after=%@", [[formatter stringFromDate:lastSyncTime] urlEncodedString]];
    }

    NSString* path = [NSString stringWithFormat:@"/v1/users/%@/messages%@", Kumulos.currentUserIdentifier, after];

    [self.kumulos.pushHttpClient get:path onSuccess:^(NSHTTPURLResponse * _Nullable response, id  _Nullable decodedBody) {
        NSArray<NSDictionary*>* messages = decodedBody;
        if (!messages.count) {
            return;
        }

        [self persistInAppMessages:messages];
        // TODO run presentation(immediate)
    } onFailure:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        // TODO
    }];
}

-(void)persistInAppMessages:(NSArray<NSDictionary*>*)messages {
    [self.messagesContext performBlock:^{
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
            NSArray<KSInAppMessage*>* fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];

            KSInAppMessage* model = fetchedObjects.count == 1 ? fetchedObjects[0] : [[KSInAppMessage alloc] initWithEntity:entity insertIntoManagedObjectContext:context];

            model.id = partId;
            model.updatedAt = [dateParser dateFromString:message[@"updatedAt"]];
            model.openedAt = [message[@"openedAt"] isEqual:NSNull.null] ? nil : [dateParser dateFromString:message[@"openedAt"]];
            model.presentedWhen = message[@"presentedWhen"];
            model.content = message[@"content"];
            model.data = [message[@"data"] isEqual:NSNull.null] ? nil : message[@"data"];
            model.badgeConfig = [message[@"badge"] isEqual:NSNull.null] ? nil : message[@"badge"];
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

#pragma mark - Data model

- (NSManagedObjectModel*)getDataModel {
    NSManagedObjectModel* model = [NSManagedObjectModel new];

    if (!model) {
        return nil;
    }

    NSEntityDescription* messageEntity = [NSEntityDescription new];
    messageEntity.name = @"Message";
    messageEntity.managedObjectClassName = NSStringFromClass(KSInAppMessage.class);

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
