//
//  KSInAppPresenter.h
//  KumulosSDK
//

@import WebKit;

#import <Foundation/Foundation.h>
#import "../Kumulos.h"
#import "../KumulosInApp.h"
#import "KSInAppModels.h"

@interface KSInAppPresenter : NSObject <WKScriptMessageHandler,WKNavigationDelegate>

- (instancetype _Nullable) initWithKumulos:(Kumulos* _Nonnull) kumulos;
- (void) queueMessagesForPresentation:(NSArray<KSInAppMessage*>* _Nonnull) messages presentingTickles:(NSOrderedSet<NSNumber*>* _Nullable)tickleIds;

@end

@interface KSInAppButtonPress ()

+ (instancetype _Nonnull) forInAppMessage:(KSInAppMessage* _Nonnull)message withDeepLink:(NSDictionary* _Nonnull)deepLinkData;

@end
