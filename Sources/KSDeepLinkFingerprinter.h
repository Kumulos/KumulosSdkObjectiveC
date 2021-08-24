//
//  KSDeepLinkFingerprinter.h
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 23/08/2021.
//

#ifndef KSDeepLinkFingerprinter_h
#define KSDeepLinkFingerprinter_h

typedef void (^ _Nonnull PendingWatcher)(id _Nonnull result);

@interface KSDeepLinkFingerprinter : NSObject

- (instancetype _Nonnull)init;
- (void) getFingerprintComponents:(PendingWatcher _Nonnull)onGenerated;

@end

#endif /* KSDeepLinkFingerprinter_h */
