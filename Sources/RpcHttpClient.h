//
//  RpcHttpClient.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AFNetworking;

@interface RpcHttpClient : AFHTTPSessionManager

-  (instancetype) initWithApiKey:(NSString*) apiKey andSecretKey:(NSString*) secretKey;

@end
