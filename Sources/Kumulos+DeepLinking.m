//
//  Kumulos+DeepLinking.m
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 12/11/2020.
//

#import <Foundation/Foundation.h>
#import "Kumulos+DeepLinking.h"
#import "Kumulos.h"
#import "Kumulos+Protected.h"//TODO: does not make protected methods public, right?

@interface KSDeepLinkContent ()
- (instancetype _Nonnull) init:(NSString* _Nullable)title from:(NSString* _Nullable) description;
@end

@implementation KSDeepLinkContent
@synthesize description;
- (instancetype _Nonnull) init:(NSString* _Nullable)title from:(NSString* _Nullable) description {
    self.title = title;
    self.description = description;
    
    return self;
}
@end


@implementation KSDeepLink
- (instancetype _Nullable) init:(NSURL*)url from:(NSDictionary*) data {
    NSDictionary* linkData = data[@"linkData"];
    NSDictionary* content = data[@"content"];
    if (linkData == nil || content == nil){
        return nil;
    }
   
    self.url = url;
   
    self.content = [[KSDeepLinkContent alloc] init:content[@"title"] from:content[@"description"]];
    self.data = linkData;
  
    return self;
}
@end


@implementation Kumulos (DeepLinking)

+ (BOOL) application:(UIApplication* _Nonnull)application continueUserActivity:(NSUserActivity* _Nonnull)userActivity restorationHandler:(void (^_Nonnull)(NSArray<id<UIUserActivityRestoring>> * _Nonnull restorableObjects))restorationHandler {
    if (Kumulos.shared.deepLinkHelper == nil){
        return NO;
    }
    
    return [Kumulos.shared.deepLinkHelper handleContinuation:userActivity];
}

+ (void) scene:(UIScene* _Nonnull)scene continueUserActivity:(NSUserActivity* _Nonnull)userActivity  API_AVAILABLE(ios(13.0)){
    if (Kumulos.shared.deepLinkHelper == nil){
        return;
    }
    
    [Kumulos.shared.deepLinkHelper handleContinuation:userActivity];
}

@end
