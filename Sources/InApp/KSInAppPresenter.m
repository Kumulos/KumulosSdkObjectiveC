//
//  KSInAppPresenter.m
//  KumulosSDK
//

#import "KSInAppPresenter.h"
#import "../Kumulos+Analytics.h"
#import "../KumulosPushSubscriptionManager.h"
#import "../Kumulos+Push.h"
#import "../Kumulos+Protected.h"
@import UIKit;
@import WebKit;
@import StoreKit;

NSString* const _Nonnull KSInAppRendererUrl = @"https://iar.app.delivery";

NSString* const _Nonnull KSInAppActionCloseMessage = @"closeMessage";
NSString* const _Nonnull KSInAppActionTrackEvent = @"trackConversionEvent";
NSString* const _Nonnull KSInAppActionPromptPushPermission = @"promptPushPermission";
NSString* const _Nonnull KSInAppActionSubscribeChannel = @"subscribeToChannel";
NSString* const _Nonnull KSInAppActionOpenUrl = @"openUrl";
NSString* const _Nonnull KSInAppActionDeepLink = @"deepLink";
NSString* const _Nonnull KSInAppActionRequestRating = @"requestAppStoreRating";

@interface KSInAppPresenter ()

@property (nonatomic) Kumulos* _Nonnull kumulos;
@property (nonatomic) WKWebView* _Nullable webView;
@property (nonatomic) UIActivityIndicatorView* _Nullable loadingSpinner;
@property (nonatomic) UIView* _Nullable frame;
@property (nonatomic) UIWindow* _Nullable window;

@property (nonatomic) WKUserContentController* contentController;

@property (atomic) NSMutableOrderedSet<KSInAppMessage*>* _Nonnull messageQueue;
@property (atomic) NSMutableOrderedSet<NSNumber*>* _Nonnull pendingTickleIds;
@property (atomic) KSInAppMessage* _Nullable currentMessage;

@end

@implementation KSInAppPresenter

- (instancetype)initWithKumulos:(Kumulos *)kumulos {
    if (self = [super init]) {
        self.kumulos = kumulos;
        self.messageQueue = [[NSMutableOrderedSet alloc] initWithCapacity:5];
        self.pendingTickleIds = [[NSMutableOrderedSet alloc] initWithCapacity:2];
        self.currentMessage = nil;
    }

    return self;
}

- (void) queueMessagesForPresentation:(NSArray<KSInAppMessage*>*)messages presentingTickles:(NSArray<NSNumber*>*)tickleIds {
    @synchronized (self.messageQueue) {
        if (!messages.count && !self.messageQueue.count) {
            return;
        }

        for (KSInAppMessage* message in messages) {
            if ([self.messageQueue containsObject:message]) {
                continue;
            }

            [self.messageQueue addObject:message];
        }

        if (tickleIds != nil && tickleIds.count > 0) {
            for (NSNumber* tickleId in [tickleIds reverseObjectEnumerator]) {
                if ([self.pendingTickleIds containsObject:tickleId]) {
                    continue;
                }

                [self.pendingTickleIds insertObject:tickleId atIndex:0];
            }

            [self.messageQueue sortUsingComparator:^NSComparisonResult(KSInAppMessage* _Nonnull a, KSInAppMessage* _Nonnull b) {
                BOOL aIsTickle = [self.pendingTickleIds containsObject:a.id];
                BOOL bIsTickle = [self.pendingTickleIds containsObject:b.id];

                if (aIsTickle && !bIsTickle) {
                    return NSOrderedAscending;
                } else if (!aIsTickle && bIsTickle) {
                    return NSOrderedDescending;
                } else if (aIsTickle && bIsTickle) {
                    NSUInteger aIdx = [self.pendingTickleIds indexOfObject: a.id];
                    NSUInteger bIdx = [self.pendingTickleIds indexOfObject: b.id];

                    if (aIdx < bIdx) {
                        return NSOrderedAscending;
                    } else if (aIdx > bIdx) {
                        return NSOrderedDescending;
                    }
                }

                return NSOrderedSame;
            }];
        }
    }

    [self performSelectorOnMainThread:@selector(initViews) withObject:nil waitUntilDone:YES];

    if (self.currentMessage
        && ![self.currentMessage.id isEqualToNumber:self.messageQueue[0].id]
        && [self.messageQueue[0].id isEqualToNumber:self.pendingTickleIds[0]]) {
        [self presentFromQueue];
    }
}

- (void) presentFromQueue {
    if (!self.messageQueue.count) {
        NSLog(@"Queue is empty, aborting");
        return;
    }

    if (self.loadingSpinner) {
        [self.loadingSpinner performSelectorOnMainThread:@selector(startAnimating) withObject:nil waitUntilDone:YES];
    }

    self.currentMessage = self.messageQueue[0];
    [self postClientMessage:@"PRESENT_MESSAGE" withData:self.currentMessage.content];
}

- (void) handleMessageClosed {
    @synchronized (self.messageQueue) {
        [self.messageQueue removeObjectAtIndex:0];
        [self.pendingTickleIds removeObject:self.currentMessage.id];
        self.currentMessage = nil;

        if (!self.messageQueue.count) {
            [self.pendingTickleIds removeAllObjects];
            [self performSelectorOnMainThread:@selector(destroyViews) withObject:nil waitUntilDone:YES];
        } else {
            [self presentFromQueue];
        }
    }
}

- (void) cancelCurrentPresentationQueue:(BOOL)waitForViewCleanup {
    @synchronized (self.messageQueue) {
        [self.messageQueue removeAllObjects];
        [self.pendingTickleIds removeAllObjects];
        self.currentMessage = nil;
    }

    [self performSelectorOnMainThread:@selector(destroyViews) withObject:nil waitUntilDone:waitForViewCleanup];
}

#pragma mark - View management

- (void) initViews {
    if (self.window != nil) {
        return;
    }

    // Window / frame setup
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.windowLevel = UIWindowLevelAlert;
    [self.window setRootViewController:[UIViewController new]];

    self.frame = [[UIView alloc] initWithFrame:self.window.frame];
    self.frame.backgroundColor = UIColor.clearColor;
    [self.window.rootViewController setView:self.frame];

    [self.window setHidden:NO];

    // Webview
    self.contentController = [WKUserContentController new];
    [self.contentController addScriptMessageHandler:self name:@"inAppHost"];

    WKWebViewConfiguration* config = [WKWebViewConfiguration new];
    [config setUserContentController:self.contentController];

#ifdef DEBUG
    [config.preferences setValue:@YES forKey:@"developerExtrasEnabled"];
#endif

    self.webView = [[WKWebView alloc] initWithFrame:self.frame.frame configuration:config];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.backgroundColor = UIColor.clearColor;
    self.webView.scrollView.backgroundColor = UIColor.clearColor;
    self.webView.opaque = NO;
    self.webView.navigationDelegate = self;
    self.webView.scrollView.scrollEnabled = NO;
    if (@available(iOS 11.0.0, *)) {
        // Allow content to pass under the notch / home button
        [self.webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }

    [self.frame addSubview:self.webView];

    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:KSInAppRendererUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30];
    [self.webView loadRequest:req];

    // Spinner
    self.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingSpinner.hidesWhenStopped = YES;
    [self.loadingSpinner startAnimating];
    [self.frame addSubview:self.loadingSpinner];

    NSLayoutConstraint* horCon = [NSLayoutConstraint constraintWithItem:self.loadingSpinner attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.frame attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    NSLayoutConstraint* verCon = [NSLayoutConstraint constraintWithItem:self.loadingSpinner attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.frame attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    [self.frame addConstraints:@[horCon, verCon]];

    [self.frame bringSubviewToFront:self.loadingSpinner];
}

- (void) destroyViews {
    if (!self.window) {
        return;
    }

    [self.window setHidden:YES];

    [self.loadingSpinner removeFromSuperview];
    self.loadingSpinner = nil;

    [self.webView removeFromSuperview];
    self.webView = nil;

    [self.frame removeFromSuperview];
    self.frame = nil;

    self.window = nil;
}

#pragma mark - WKWebView delegates & helpers

- (void) postClientMessage:(NSString* _Nonnull)type withData:(id _Nullable)data {
    NSDictionary* msg = @{@"type": type, @"data": data != nil ? data : NSNull.null};
    NSData* jsonMsg = [NSJSONSerialization dataWithJSONObject:msg options:0 error:nil];
    NSString* evalString = [NSString stringWithFormat:@"postHostMessage(%@);", [[NSString alloc] initWithData:jsonMsg encoding:NSUTF8StringEncoding]];

    [self.webView evaluateJavaScript:evalString completionHandler:nil];
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if (![message.name isEqual:@"inAppHost"]) {
        return;
    }

    NSLog(@"Received message: %@", message.body);
    NSString* type = message.body[@"type"];
    if ([type isEqualToString:@"READY"]) {
        @synchronized (self.messageQueue) {
            [self presentFromQueue];
        }
    } else if ([type isEqualToString:@"MESSAGE_OPENED"]) {
        [self.loadingSpinner stopAnimating];

        if (@available(iOS 10, *)) {
            NSString* tickleNotificationId = [NSString stringWithFormat:@"k-in-app-message:%@", self.currentMessage.id];
            [UNUserNotificationCenter.currentNotificationCenter removeDeliveredNotificationsWithIdentifiers:@[tickleNotificationId]];
        }

        [self.kumulos.inAppHelper trackMessageOpened:self.currentMessage];
    } else if ([type isEqualToString:@"MESSAGE_CLOSED"]) {
        [self handleMessageClosed];
    } else if ([type isEqualToString:@"EXECUTE_ACTIONS"]) {
        [self handleActions:message.body[@"data"][@"actions"]];
    } else {
        NSLog(@"Unknown message type: %@", type);
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // Noop
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self cancelCurrentPresentationQueue:NO];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self cancelCurrentPresentationQueue:NO];
}

- (void) handleActions:(NSArray<NSDictionary*>*)actions {
    NSLog(@"%@", actions);

    BOOL hasClose = NO;
    NSString* trackEvent = nil;
    NSString* subscribeToChannel = nil;
    NSDictionary* userAction = nil;

    for (NSDictionary* action in actions) {
        NSString* type = action[@"type"];

        if ([type isEqualToString:KSInAppActionCloseMessage]) {
            hasClose = YES;
        } else if ([type isEqualToString:KSInAppActionTrackEvent]) {
            trackEvent = action[@"data"][@"eventType"];
        } else if ([type isEqualToString:KSInAppActionSubscribeChannel]) {
            subscribeToChannel = action[@"data"][@"channelUuid"];
        } else {
            userAction = action;
        }
    }

    if (hasClose) {
        [self.kumulos.inAppHelper markMessageDismissed:self.currentMessage];
        [self postClientMessage:@"CLOSE_MESSAGE" withData:nil];
    }

    if (trackEvent != nil) {
        [self.kumulos trackEvent:trackEvent withProperties:nil];
    }

    if (subscribeToChannel != nil) {
        KumulosPushSubscriptionManager* psm = [[KumulosPushSubscriptionManager alloc] initWithKumulos:self.kumulos];
        [psm subscribeToChannels:@[subscribeToChannel]];
    }

    if (userAction != nil) {
        [self handleUserAction:userAction];
        [self cancelCurrentPresentationQueue:YES];
    }
}

- (void) handleUserAction:(NSDictionary* _Nonnull)userAction {
    NSString* type = userAction[@"type"];
    if ([type isEqualToString:KSInAppActionPromptPushPermission]) {
        [self.kumulos pushRequestDeviceToken];
    } else if ([type isEqualToString:KSInAppActionDeepLink]) {
        if (self.kumulos.config.inAppDeepLinkHandler == nil) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary* data = userAction[@"data"][@"deepLink"] ?: @{};
            self.kumulos.config.inAppDeepLinkHandler(data);
        });
    } else if ([type isEqualToString:KSInAppActionOpenUrl]) {
        NSURL* url = [NSURL URLWithString:userAction[@"data"][@"url"]];

        if (@available(iOS 10.0.0, *)) {
            [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {
                /* noop */
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication openURL:url];
            });
        }
    } else if ([type isEqualToString:KSInAppActionRequestRating]) {
        if (@available(iOS 10.3.0, *)) {
            [SKStoreReviewController requestReview];
        } else {
            NSLog(@"Requesting a rating not supported on this iOS version");
        }
    }
}

@end
