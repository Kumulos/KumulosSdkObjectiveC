//
//  KSDeepLinkFingerprinter.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 23/08/2021.
//

#import <Foundation/Foundation.h>
@import WebKit;
#import "KSDeepLinkFingerprinter.h"

typedef NS_ENUM(NSInteger, DeferredState) {
    Pending,
    Resolved
};

@interface Deferred<R> : NSObject

- (instancetype _Nonnull)init;
- (void) resolve:(R _Nonnull)res;
- (void) then:(PendingWatcher)onResult;

@end


@implementation Deferred

NSMutableArray<PendingWatcher>* pendingWatchers;
id result;
DeferredState state;

- (instancetype _Nonnull)init {
    if (self = [super init]) {
        state = Pending;
        pendingWatchers = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

- (void) resolve:(id _Nonnull)res{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch(state){
            case Resolved:
                return;
            default:
                break;
        }
        
        state = Resolved;
        result = res;
        
        for (PendingWatcher cb in pendingWatchers) {
            cb(result);
        }
        
        [pendingWatchers removeAllObjects];
    });
}

- (void) then:(PendingWatcher)onResult{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch(state){
            case Pending:
                //TODO: test different paths?
                [pendingWatchers addObject:onResult];
                break;
            case Resolved:
                onResult(result);
                break;
        }
    });
}

@end


@implementation KSDeepLinkFingerprinter

NSString* const _Nonnull KSPrintDustRuntimeUrl = @"https://pd.app.delivery";
NSString* const _Nonnull KSPrintDustHandlerName = @"printHandler";
WKWebView* _Nullable webView;
Deferred<NSDictionary*>* _Nullable fingerprint;

- (instancetype _Nonnull)init {
    if (self = [super init]) {
        WKUserContentController* contentController = [WKUserContentController new];
        WKWebViewConfiguration* config = [WKWebViewConfiguration new];
        [config setUserContentController: contentController];
        
        webView = [[WKWebView alloc] initWithFrame:UIScreen.mainScreen.bounds configuration:config];
        
        fingerprint = [[Deferred alloc] init];
        
        [contentController addScriptMessageHandler:self name:KSPrintDustHandlerName];
        
        NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:KSPrintDustRuntimeUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
        [webView loadRequest:req];
    }
    
    return self;
}

- (void) getFingerprintComponents:(PendingWatcher _Nonnull)onGenerated {
    [fingerprint then:onGenerated];
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if (![message.name isEqual:KSPrintDustHandlerName]) {
        return;
    }
    
    NSDictionary* body = message.body;
    NSString* type = body[@"type"];
    
    if ([type isEqualToString:@"READY"]) {
        [self postClientMessage:@"REQUEST_FINGERPRINT" withData:nil];
    }
    else if ([type isEqualToString:@"FINGERPRINT_GENERATED"]){
        NSDictionary* data = body[@"data"];
        if (data == nil){
            return;
        }
        
        NSDictionary* components = data[@"components"];
        if (components == nil){
            return;
        }
        
        [fingerprint resolve:components];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self cleanupWebView];
        });
    }
    else{
        NSLog(@"Unhandled message: %@", type);
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cleanupWebView];
    });
}

- (void) postClientMessage:(NSString* _Nonnull)type withData:(id _Nullable)data {
    NSDictionary* msg = @{@"type": type, @"data": data != nil ? data : NSNull.null};
    NSData* jsonMsg = [NSJSONSerialization dataWithJSONObject:msg options:0 error:nil];
    NSString* evalString = [NSString stringWithFormat:@"postHostMessage(%@);", [[NSString alloc] initWithData:jsonMsg encoding:NSUTF8StringEncoding]];
    
    [webView evaluateJavaScript:evalString completionHandler:nil];
}


- (void)cleanupWebView {
    if (webView == nil){
        return;
    }
    
    [webView stopLoading];
    [webView.configuration.userContentController removeScriptMessageHandlerForName:KSPrintDustHandlerName];
    webView = nil;
}

@end
