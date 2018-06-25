//
//  KSHttpClient.h
//  KumulosSDK
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, KSHttpDataFormat) {
    KSHttpDataFormatPList,
    KSHttpDataFormatJson,
    KSHttpDataFormatWwwUrlEncoded
};

typedef void (^ _Nullable KSHttpSuccessBlock)(NSHTTPURLResponse* _Nullable response, id _Nullable decodedBody);
typedef void (^ _Nullable KSHttpFailureBlock)(NSHTTPURLResponse* _Nullable response, NSError* _Nullable error);

@interface KSHttpClient : NSObject

@property (nonatomic,readonly) NSURL* baseUrl;

@property (nonatomic,readonly) KSHttpDataFormat requestBodyFormat;
@property (nonatomic,readonly) KSHttpDataFormat responseBodyFormat;

@property (nonatomic, readonly) NSURLSession* urlSession;

- (instancetype _Nullable) init NS_UNAVAILABLE;

- (instancetype _Nullable) initWithBaseUrl:(NSString* _Nonnull) baseUrl requestBodyFormat:(KSHttpDataFormat) requestFormat responseBodyFormat:(KSHttpDataFormat) responseFormat;

- (void) setBasicAuthWithUser:(NSString* _Nonnull) user andPassword:(NSString*) password;

- (NSURLSessionTask*) get:(NSString* _Nonnull) path onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionTask*) post:(NSString* _Nonnull) path data:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionTask*) put:(NSString* _Nonnull) path data:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionTask*) delete:(NSString* _Nonnull) path data:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;

@end
