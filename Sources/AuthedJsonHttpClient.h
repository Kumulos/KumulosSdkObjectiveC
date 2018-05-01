//
//  AuthedJsonHttpClient.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface AuthedJsonHttpClient : AFHTTPSessionManager

-  (instancetype) initWithBaseUrl:(NSString*) baseUrl apiKey:(NSString*) apiKey andSecretKey:(NSString*) secretKey;

@end
