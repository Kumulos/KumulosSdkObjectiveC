//
//  Kumulos+Protected.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import "Kumulos.h"
#import "RpcHttpClient.h"
#import "KSHttpClient.h"

#if TARGET_OS_IOS
#import "AnalyticsHelper.h"
#endif

#define KUMULOS_INSTALL_ID_KEY @"KumulosUUID"

@interface Kumulos ()

@property (nonatomic) NSString* apiKey;
@property (nonatomic) NSString* secretKey;

@property (nonatomic) NSOperationQueue* operationQueue;

@property (nonatomic) RpcHttpClient* rpcHttpClient;
@property (nonatomic) KSHttpClient* pushHttpClient;

#if TARGET_OS_IOS
@property (nonatomic) AnalyticsHelper* analyticsHelper;
@property (nonatomic) KSHttpClient* eventsHttpClient;
#else
@property (nonatomic) KSHttpClient* statsHttpClient;
#endif

@end
