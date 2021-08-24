//
//  DeepLinkHelper.m
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 17/11/2020.
//

#import <Foundation/Foundation.h>
#import "Kumulos+DeepLinking.h"
#import "Kumulos.h"

#import "Shared/Http/KSHttpClient.h"
#import "KSKeyValPersistenceHelper.h"
#import "Shared/Http/NSString+URLEncoding.h"
#import "Kumulos+Protected.h"
#import "KumulosEvents.h"

static NSString* _Nonnull const KSDeepLinksBaseUrl = @"https://links.kumulos.com";
static NSString* _Nonnull const KSDeferredLinkCheckedKey = @"KUMULOS_DDL_CHECKED";

@interface KSDeepLinkHelper ()
@property (nonatomic) KSConfig* _Nonnull config;
@property (nonatomic) KSHttpClient* _Nullable httpClient;

- (BOOL) urlShouldBeHandled:(NSURL* _Nonnull)url;
- (void) handleDeepLinkUrl:(NSURL*)url wasDeferred:(BOOL)wasDeferred;
- (void) invokeDeepLinkHandler:(KSDeepLinkResolution) resolution url:(NSURL*) url link:(KSDeepLink* _Nullable) deepLink;
@end

@implementation KSDeepLinkHelper

BOOL anyContinuationHandled;

- (instancetype _Nonnull)init:(KSConfig* _Nonnull)config {
    self.config = config;
    
    self.httpClient = [[KSHttpClient alloc] initWithBaseUrl:KSDeepLinksBaseUrl requestBodyFormat:KSHttpDataFormatJson responseBodyFormat:KSHttpDataFormatJson];
    [self.httpClient setBasicAuthWithUser:self.config.apiKey andPassword:self.config.secretKey];
    
    anyContinuationHandled = NO;
    return self;
}

- (void) checkForNonContinuationLinkMatch {
    if ([self checkForDeferredLinkOnClipboard]) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(appBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void) appBecameActive {
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if (anyContinuationHandled) {
        return;
    }
    
    [self checkForWebToAppBannerTap];
}

- (BOOL) checkForDeferredLinkOnClipboard {
    BOOL handled = NO;
    
    BOOL checked = [KSKeyValPersistenceHelper boolForKey:KSDeferredLinkCheckedKey];
    if (checked == YES){
        return handled;
    }
    [KSKeyValPersistenceHelper setBool:true forKey:KSDeferredLinkCheckedKey];
    
    UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
    BOOL shouldCheck = NO;
    if (@available(iOS 10, *)) {
        shouldCheck = [pasteboard hasURLs];
    }
    else{
        shouldCheck = YES;
    }
    
    if (!shouldCheck){
        return handled;
    }
    
    NSURL* url = pasteboard.URL;
    if (url == nil || ![self urlShouldBeHandled:url]){
        return handled;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSURL *nextUrl = (NSURL *)evaluatedObject;
        return url != nextUrl;
    }];
    
    pasteboard.URLs = [pasteboard.URLs filteredArrayUsingPredicate:predicate];
    [self handleDeepLinkUrl:url wasDeferred:YES];
    
    handled = YES;
    
    return handled;
}

- (void) checkForWebToAppBannerTap {
    KSDeepLinkFingerprinter* fp = [[KSDeepLinkFingerprinter alloc] init];
    
    [fp getFingerprintComponents:^(id _Nonnull components) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleFingerprintComponents: (NSDictionary*) components];
        });
    }];
}

- (BOOL) urlShouldBeHandled:(NSURL* _Nonnull)url {
    NSString* host = url.host;
    if (host == nil){
        return NO;
    }
    
    NSURL* cname = self.config.deepLinkCname;
    return [host hasSuffix:@"lnk.click"] || (cname != nil && [host isEqualToString:cname.host]);
}

- (void) handleDeepLinkUrl:(NSURL*)url wasDeferred:(BOOL)wasDeferred {
    NSCharacterSet *charc=[NSCharacterSet characterSetWithCharactersInString:@"/"];
    
    NSString* slug = [[url.path stringByTrimmingCharactersInSet:charc] urlEncodedStringForUrl];
    if (slug == nil){
        slug = @"";
    }
    
    NSString* path = [NSString stringWithFormat:@"/v1/deeplinks/%@?wasDeferred=%@", slug, wasDeferred ? @"1" : @"0"];
    NSString* queryString = [url query];
    if (queryString != nil){
        path = [NSString stringWithFormat: @"%@&%@", path, queryString];
    }
    
    [self.httpClient sendRequest:KSHttpMethodGet toPath:path withData:nil onSuccess:^(NSHTTPURLResponse * _Nullable response, id  _Nullable decodedBody) {
        
        switch(response.statusCode){
            case 200: {
                KSDeepLink* link = nil;
                if (decodedBody != nil){
                    link = [[KSDeepLink alloc] init:url from:decodedBody];
                }
                
                if (link == nil){
                    [self invokeDeepLinkHandler: KSDeepLinkResolutionLookupFailed url:url link:nil];
                    return;
                }
                
                [self invokeDeepLinkHandler: KSDeepLinkResolutionLinkMatched url:url link:link];
                
                NSDictionary* linkProps = @{@"url": url.absoluteString, @"wasDeferred": wasDeferred ? @YES : @NO};
                [Kumulos.shared.analyticsHelper trackEvent:KumulosEventDeepLinkMatched withProperties:linkProps];
                
                break;
            }
                
            default:
                [self invokeDeepLinkHandler: KSDeepLinkResolutionLookupFailed url:url link: nil];
                return;
        }
        
    } onFailure:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        switch(response.statusCode){
            case 404:
                [self invokeDeepLinkHandler:KSDeepLinkResolutionLinkNotFound url:url link:nil];
                break;
            case 410:
                [self invokeDeepLinkHandler: KSDeepLinkResolutionLinkExpired url:url link:nil];
                break;
            case 429:
                [self invokeDeepLinkHandler: KSDeepLinkResolutionLinkLimitExceeded url:url link:nil];
                break;
            default:
                [self invokeDeepLinkHandler: KSDeepLinkResolutionLookupFailed url:url link:nil];
                break;
        }
    }];
}

- (void) handleFingerprintComponents:(NSDictionary* _Nonnull)components {
    //TODO: remove
    for(NSString *key in [components allKeys]) {
        NSLog(@"key: %@, value: %@",key, [components objectForKey:key]);
    }
    
    NSError* err = nil;
    NSData* componentJson = [NSJSONSerialization dataWithJSONObject:components options:0 error:&err];
    if (nil != err) {
        return;
    }
    NSString* encodedComponents = [[componentJson base64EncodedStringWithOptions:0] urlEncodedStringForUrl];
    NSString* path = [NSString stringWithFormat:@"/v1/deeplinks/_taps?fingerprint=%@", encodedComponents];
    
    [self.httpClient sendRequest:KSHttpMethodGet toPath:path withData:nil onSuccess:^(NSHTTPURLResponse * _Nullable response, id  _Nullable decodedBody) {
        
        switch(response.statusCode){
            case 200: {
                if (decodedBody == nil){
                    // Fingerprint matches that fail to parse correctly can't know the URL so
                    // don't invoke any error handler.
                    return;
                }
                
                NSString* urlString = decodedBody[@"linkUrl"];
                if (urlString == nil){
                    return;
                }
                
                NSURL* url = [NSURL URLWithString:urlString];
                if (url == nil){
                    return;
                }
                
                KSDeepLink* link = [[KSDeepLink alloc] init:url from:decodedBody];
                
                [self invokeDeepLinkHandler: KSDeepLinkResolutionLinkMatched url:url link:link];
                
                NSDictionary* linkProps = @{@"url": url.absoluteString, @"wasDeferred": @NO};
                [Kumulos.shared.analyticsHelper trackEvent:KumulosEventDeepLinkMatched withProperties:linkProps];
                
                break;
            }
            default:
                // Noop
                break;
        }
    } onFailure:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error, id _Nullable decodedBody) {
        if (decodedBody == nil){
            return;
        }
        
        NSString* urlString = decodedBody[@"linkUrl"];
        if (urlString == nil){
            return;
        }
        
        NSURL* url = [NSURL URLWithString:urlString];
        if (url == nil){
            return;
        }
        
        switch(response.statusCode){
            case 410:
                [self invokeDeepLinkHandler: KSDeepLinkResolutionLinkExpired url:url link:nil];
                break;
            case 429:
                [self invokeDeepLinkHandler: KSDeepLinkResolutionLinkLimitExceeded url:url link:nil];
                break;
            default:
                // Noop
                break;
        }
    }];
}

- (void) invokeDeepLinkHandler:(KSDeepLinkResolution) resolution url:(NSURL*) url link:(KSDeepLink* _Nullable) deepLink {
    if (self.config.deepLinkHandler == nil){
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.config.deepLinkHandler(resolution, url, deepLink);
    });
}


- (BOOL) handleContinuation:(NSUserActivity* _Nonnull) userActivity{
    if (self.config.deepLinkHandler == nil){
        NSLog(@"Kumulos deep link handler not configured, aborting...");
        return NO;
    }
    
    if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]){
        return NO;
    }
    
    NSURL* url = userActivity.webpageURL;
    if (url == nil){
        return NO;
    }
    
    if (![self urlShouldBeHandled:url]){
        return NO;
    }
    
    anyContinuationHandled = YES;
    
    [self handleDeepLinkUrl:url wasDeferred:NO];
    return YES;
}

@end
