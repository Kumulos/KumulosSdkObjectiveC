//
//  KSDeepLinkFingerprinter.h
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 23/08/2021.
//

@import WebKit;

#ifndef KSDeepLinkFingerprinter_h
#define KSDeepLinkFingerprinter_h

typedef void (^ _Nonnull KSPendingWatcher)(id _Nonnull result);

@interface KSDeepLinkFingerprinter : NSObject <WKScriptMessageHandler, WKNavigationDelegate>

- (instancetype _Nonnull)init;
- (void) getFingerprintComponents:(KSPendingWatcher _Nonnull)onGenerated;

@end

#endif /* KSDeepLinkFingerprinter_h */
