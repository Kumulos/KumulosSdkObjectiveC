//
//  DeepLinkHelper.h
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 17/11/2020.
//

@interface KSDeepLinkHelper : NSObject


- (instancetype _Nonnull ) init:(KSConfig* _Nonnull) config;
- (void) checkForDeferredLink;
- (BOOL) handleContinuation:(NSUserActivity* _Nonnull) userActivity;
    
@end
