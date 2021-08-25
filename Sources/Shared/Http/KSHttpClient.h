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

extern NSString* _Nonnull const KSHttpMethodGet;
extern NSString* _Nonnull const KSHttpMethodPost;
extern NSString* _Nonnull const KSHttpMethodPut;
extern NSString* _Nonnull const KSHttpMethodDelete;

typedef void (^ _Nullable KSHttpSuccessBlock)(NSHTTPURLResponse* _Nullable response, id _Nullable decodedBody);
typedef void (^ _Nullable KSHttpFailureBlock)(NSHTTPURLResponse* _Nullable response, NSError* _Nullable error, id _Nullable decodedBody);

@interface KSHttpClient : NSObject

@property (nonatomic,readonly) NSURL* _Nullable baseUrl;

@property (nonatomic,readonly) KSHttpDataFormat requestBodyFormat;
@property (nonatomic,readonly) KSHttpDataFormat responseBodyFormat;

@property (nonatomic, readonly) NSURLSession* _Nullable urlSession;

- (instancetype _Nullable) init NS_UNAVAILABLE;

- (instancetype _Nullable) initWithBaseUrl:(NSString* _Nonnull) baseUrl requestBodyFormat:(KSHttpDataFormat) requestFormat responseBodyFormat:(KSHttpDataFormat) responseFormat;

- (void) setBasicAuthWithUser:(NSString* _Nonnull) user andPassword:(NSString* _Nonnull) password;

- (NSURLSessionDataTask* _Nonnull) sendRequest:(NSString* _Nonnull) method toPath:(NSString* _Nonnull) path withData:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionDataTask* _Nonnull) get:(NSString* _Nonnull) path onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionDataTask* _Nonnull) post:(NSString* _Nonnull) path data:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionDataTask* _Nonnull) put:(NSString* _Nonnull) path data:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionDataTask* _Nonnull) delete:(NSString* _Nonnull) path data:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;

- (void) invalidateSessionCancelingTasks:(BOOL)cancelTasks;

@end
