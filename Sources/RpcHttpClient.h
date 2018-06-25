//
//  RpcHttpClient.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RpcHttpClient : NSObject

-  (instancetype) initWithApiKey:(NSString*) apiKey andSecretKey:(NSString*) secretKey;

@end
