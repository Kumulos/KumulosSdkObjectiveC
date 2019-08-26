//
//  KSInAppPresenter.h
//  KumulosSDK
//

@import WebKit;

#import <Foundation/Foundation.h>
#import "../Kumulos.h"
#import "KSInAppModels.h"

@interface KSInAppPresenter : NSObject <WKScriptMessageHandler,WKNavigationDelegate>

- (instancetype _Nullable) initWithKumulos:(Kumulos* _Nonnull) kumulos;
- (void) queueMessagesForPresentation:(NSArray<KSInAppMessage*>* _Nonnull) messages presentingTickles:(NSOrderedSet<NSNumber*>* _Nullable)tickleIds;

@end
