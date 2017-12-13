//
//  Kumulos+Protected.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

@import AFNetworking;
#import "Kumulos.h"
#import "RpcHttpClient.h"
#import "AuthedJsonHttpClient.h"

#if TARGET_OS_IOS
#import "AnalyticsHelper.h"
#endif

#define KUMULOS_INSTALL_ID_KEY @"KumulosUUID"

@interface Kumulos ()

@property (nonatomic) NSString* apiKey;
@property (nonatomic) NSString* secretKey;

@property (nonatomic) NSOperationQueue* operationQueue;

@property (nonatomic) RpcHttpClient* rpcHttpClient;
@property (nonatomic) AuthedJsonHttpClient* statsHttpClient;
@property (nonatomic) AuthedJsonHttpClient* pushHttpClient;

#if TARGET_OS_IOS
@property (nonatomic) AnalyticsHelper* analyticsHelper;
#endif

@end
