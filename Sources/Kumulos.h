//
//  Kumulos.h
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
#else
#import <UIKit/UIKit.h>
#endif

@class KSAPIOperation;
@class KSAPIResponse;
@protocol KSAPIOperationDelegate;

typedef void (^ _Nullable KSAPIOperationSuccessBlock)(KSAPIResponse* _Nonnull, KSAPIOperation* _Nonnull);
typedef void (^ _Nullable KSAPIOperationFailureBlock)(NSError* _Nonnull, KSAPIOperation* _Nonnull);

/**
 * The main Kumulos SDK class allows interaction API methods
 * and the push notification service.
 */
@interface Kumulos : NSObject

/// The Kumulos RPC API session token
@property (nonnull) NSString* sessionToken;

/**
 * Gets the unique Kumulos installation ID
 * @returns NSString
 */
+ (NSString* _Nonnull) installId;

/**
 * Initializes Kumulos with the given API key & secret
 * @param APIKey The Kumulos app API key
 * @param secretKey The Kumulos app secret key
 * @returns Kumulos
 */
- (instancetype _Nullable) initWithAPIKey:(NSString* _Nonnull)APIKey andSecretKey:(NSString* _Nonnull)secretKey;

/**
 * Calls a Kumulos API method, passing results in block handlers
 * @param method The Kumulos API method alias
 * @param success The success result handler block
 * @param failure The error result handler block
 * @returns KSAPIOperation
 */
- (KSAPIOperation* _Nonnull) callMethod:(NSString* _Nonnull)method withSuccess:(KSAPIOperationSuccessBlock)success andFailure:(KSAPIOperationFailureBlock)failure;

/**
 * Calls a Kumulos API method, passing results in block handlers
 * @param method The Kumulos API method alias
 * @param params The API method parameters map
 * @param success The success result handler block
 * @param failure The error result handler block
 * @returns KSAPIOperation
 */
- (KSAPIOperation* _Nonnull) callMethod:(NSString* _Nonnull)method withParams:(NSDictionary* _Nullable)params success:(KSAPIOperationSuccessBlock)success andFailure:(KSAPIOperationFailureBlock)failure;

/**
 * Calls a Kumulos API method, passing results to the specified delegate
 * @param method The Kumulos API method alias
 * @param delegate The KSAPIOperationDelegate handler for success and failure
 * @returns KSAPIOperation
 */
- (KSAPIOperation* _Nonnull) callMethod:(NSString* _Nonnull)method withDelegate:(id <KSAPIOperationDelegate> _Nullable) delegate;

/**
 * Calls a Kumulos API method, passing results to the specified delegate
 * @param method The Kumulos API method alias
 * @param params The API method parameters map
 * @param delegate The KSAPIOperationDelegate handler for success and failure
 * @returns KSAPIOperation
 */
- (KSAPIOperation* _Nonnull) callMethod:(NSString* _Nonnull)method withParams:(NSDictionary* _Nullable)params andDelegate:(id <KSAPIOperationDelegate> _Nullable)delegate;

@end

/// The error domain used by the Kumulos SDK
static NSString* _Nonnull const KSErrorDomain = @"com.kumulos.errors";

/// Error codes the SDK can produce within the KSErrorDomain
typedef NS_ENUM(NSInteger, KSErrorCode) {
    KSErrorCodeNetworkError,
    KSErrorCodeRpcError,
    KSErrorCodeUnknownError,
    KSErrorCodeValidationError
};
