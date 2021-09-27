//
//  Kumulos+DeepLinking.h
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 12/11/2020.
//

#import <KumulosSDK/Kumulos.h>

@interface Kumulos (DeepLinking)
+ (void) scene:(UIScene* _Nonnull)scene continueUserActivity:(NSUserActivity* _Nonnull)userActivity  API_AVAILABLE(ios(13.0));
+ (BOOL) application:(UIApplication* _Nonnull)application continueUserActivity:(NSUserActivity* _Nonnull)userActivity restorationHandler:(void (^_Nonnull)(NSArray<id<UIUserActivityRestoring>> * _Nonnull restorableObjects))restorationHandler;
@end



@interface KSDeepLinkContent : NSObject
@property (nonatomic) NSString* _Nullable title;
@property (nonatomic) NSString* _Nullable description;
@end


@interface KSDeepLink : NSObject
@property (nonatomic) NSURL* _Nonnull url;
@property (nonatomic) KSDeepLinkContent* _Nonnull content;
@property (nonatomic) NSDictionary* _Nonnull data;

- (instancetype _Nullable) init:(NSURL* _Nonnull)url from:(NSDictionary* _Nullable) jsonData;
@end




