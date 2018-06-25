//
//  AuthedJsonHttpClient.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AuthedJsonHttpClient : NSObject

-  (instancetype) initWithBaseUrl:(NSString*) baseUrl apiKey:(NSString*) apiKey andSecretKey:(NSString*) secretKey;

@end
