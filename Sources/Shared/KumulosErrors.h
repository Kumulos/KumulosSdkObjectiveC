//
//  KumulosErrors.h
//  KumulosSDK
//

#import <Foundation/Foundation.h>

/// The error domain used by the Kumulos SDK
static NSString* _Nonnull const KSErrorDomain = @"com.kumulos.errors";

/// Error codes the SDK can produce within the KSErrorDomain
typedef NS_ENUM(NSInteger, KSErrorCode) {
    KSErrorCodeNetworkError,
    KSErrorCodeRpcError,
    KSErrorCodeUnknownError,
    KSErrorCodeValidationError,
    KSErrorCodeHttpBadStatus
};
