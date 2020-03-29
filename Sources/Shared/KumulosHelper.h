//
//  KumulosHelper.h
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#define KS_MESSAGE_TYPE_PUSH 1
#define KS_MESSAGE_TYPE_IN_APP 2

@interface KumulosHelper : NSObject

+ (NSString* _Nonnull) installId;
+ (NSString* _Nonnull) currentUserIdentifier;
+ (NSString* _Nonnull) userIdLocker;

@end
