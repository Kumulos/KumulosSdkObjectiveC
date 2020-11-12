//
//  KumulosPushSubscriptionManager.m
//  KumulosSDK
//
//  Copyright © 2017 kumulos. All rights reserved.
//

#import "KumulosPushSubscriptionManager.h"
#import "Kumulos+Protected.h"
#import "KumulosHelper.h"
#import "Shared/Http/NSString+URLEncoding.h"

@interface KumulosPushSubscriptionManager ()

@property (nonatomic) Kumulos* kumulos;

@end

@implementation KSPushChannel

+ (instancetype _Nonnull) createFromObject:(id)object {
    KSPushChannel* channel = [[KSPushChannel alloc] init];
    
    channel->_uuid = object[@"uuid"];
    channel->_name = ([object[@"name"] isEqual:[NSNull null]]) ? nil : object[@"name"];
    channel->_meta = ([object[@"meta"] isEqual:[NSNull null]]) ? nil : object[@"meta"];
    channel->_isSubscribed = [object[@"subscribed"] boolValue];
    
    return channel;
}

@end

@implementation KumulosPushSubscriptionManager

- (instancetype _Nonnull) initWithKumulos:(Kumulos*) client {
    if (self = [super init]) {
        self.kumulos = client;
    }
    
    return self;
}

- (void) subscribeToChannels:(NSArray<NSString *> *)uuids {
    [self subscribeToChannels:uuids onComplete:nil];
}

- (void) subscribeToChannels:(NSArray<NSString *> *)uuids onComplete:(KSPushSubscriptionCompletionBlock)complete {
    NSDictionary* params = @{@"uuids": uuids};
    NSString* path = [NSString stringWithFormat:@"%@/channels/subscriptions", [self getSubscriptionRequestBaseUrl]];
    
    [self makeRequest:KSHttpMethodPost to:path withData:params andCompletion:complete];
}

- (void) unsubscribeFromChannels:(NSArray<NSString *> *)uuids{
    [self unsubscribeFromChannels:uuids onComplete:nil];
}

- (void) unsubscribeFromChannels:(NSArray<NSString *> *)uuids onComplete:(KSPushSubscriptionCompletionBlock)complete {
    NSDictionary* params = @{@"uuids": uuids};
    NSString* path = [NSString stringWithFormat:@"%@/channels/subscriptions", [self getSubscriptionRequestBaseUrl]];
    
    [self makeRequest:KSHttpMethodDelete to:path withData:params andCompletion:complete];
}

- (void) setSubscriptions:(NSArray<NSString *> *)uuids {
    [self setSubscriptions:uuids onComplete:nil];
}

- (void) setSubscriptions:(NSArray<NSString *> *)uuids onComplete:(KSPushSubscriptionCompletionBlock)complete {
    NSDictionary* params = @{@"uuids": uuids};
    NSString* path = [NSString stringWithFormat:@"%@/channels/subscriptions", [self getSubscriptionRequestBaseUrl]];
    
    [self makeRequest:KSHttpMethodPut to:path withData:params andCompletion:complete];
}

- (void) clearSubscriptions {
    [self clearSubscriptions:nil];
}

- (void) clearSubscriptions:(KSPushSubscriptionCompletionBlock)complete {
    [self setSubscriptions:@[] onComplete:complete];
}

- (void) createChannelWithUuid:(NSString *)uuid shouldSubscribe:(BOOL)subscribe name:(NSString *)name showInPortal:(BOOL)shownInPortal andMeta:(NSDictionary *)meta onComplete:(KSPushChannelSuccessBlock)complete {
    
    if (shownInPortal && (name == nil || name.length == 0)) {
        complete([NSError
                  errorWithDomain:KSErrorDomain
                  code:KSErrorCodeValidationError
                  userInfo:@{@"error": @"Name is required to show a channel in the portal"}
                  ],
                 nil);
        return;
    }
    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:5];
    
    params[@"uuid"] = uuid;
    params[@"showInPortal"] = @(shownInPortal);
    
    if (name && name.length > 0) {
        params[@"name"] = name;
    }
    
    if (subscribe) {
        params[@"userIdentifier"] = [KumulosHelper currentUserIdentifier];
    }
    
    if (meta) {
        params[@"meta"] = meta;
    }
    
    NSString* path = @"/v1/channels";
    
    [self.kumulos.coreHttpClient post:path data:params onSuccess:^(NSHTTPURLResponse * _Nullable response, id  _Nullable decodedBody) {
        if (nil == decodedBody) {
            complete([NSError
                      errorWithDomain:KSErrorDomain
                      code:KSErrorCodeUnknownError
                      userInfo:@{@"error": @"No channel returned for create request"}
                      ], nil);
            return;
        }
        
        KSPushChannel* channel = [KSPushChannel createFromObject:decodedBody];
        complete(nil, channel);
    } onFailure:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        complete(error, nil);
    }];
}

- (void) listChannels:(KSPushChannelsSuccessBlock)complete {
    NSString* path = [NSString stringWithFormat:@"%@/channels", [self getSubscriptionRequestBaseUrl]];
    
    [self.kumulos.coreHttpClient get:path onSuccess:^(NSHTTPURLResponse * _Nullable response, id  _Nullable decodedBody) {
        if (nil == decodedBody) {
            complete([NSError
                      errorWithDomain:KSErrorDomain
                      code:KSErrorCodeUnknownError
                      userInfo:@{@"error": @"No channels returned for list request"}
                      ], nil);
            return;
        }
        
        NSArray* data = decodedBody;
        NSMutableArray<KSPushChannel*>* channels = [[NSMutableArray alloc] initWithCapacity:data.count];
        
        [data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [channels addObject:[KSPushChannel createFromObject:obj]];
        }];
        
        complete(nil, channels);
    } onFailure:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        complete(error, nil);
    }];
}

- (void) makeRequest:(NSString*) method to:(NSString*) path withData:(id)data andCompletion:(KSPushSubscriptionCompletionBlock) complete {
    [self.kumulos.coreHttpClient sendRequest:method toPath:path withData:data onSuccess:^(NSHTTPURLResponse * _Nullable response, id  _Nullable decodedBody) {
        if (complete) {
            complete(nil);
        }
    } onFailure:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (complete) {
            complete(error);
        }
    }];
}

- (NSString*) getSubscriptionRequestBaseUrl {
    NSString* encodedIdentifier = [KumulosHelper.currentUserIdentifier urlEncodedStringForUrl];
    return [NSString stringWithFormat:@"/v1/users/%@", encodedIdentifier];
}

@end

