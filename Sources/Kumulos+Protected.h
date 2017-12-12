//
//  Kumulos+Protected.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

@import CoreData;
@import AFNetworking;
#import "Kumulos.h"
#import "RpcHttpClient.h"
#import "AuthedJsonHttpClient.h"

#define KUMULOS_INSTALL_ID_KEY @"KumulosUUID"

@interface Kumulos ()

@property (nonatomic) NSString* apiKey;
@property (nonatomic) NSString* secretKey;

@property (nonatomic) NSOperationQueue* operationQueue;

@property (nonatomic) RpcHttpClient* rpcHttpClient;
@property (nonatomic) AuthedJsonHttpClient* statsHttpClient;
@property (nonatomic) AuthedJsonHttpClient* pushHttpClient;

@property NSManagedObjectContext* analyticsContext;

@end
