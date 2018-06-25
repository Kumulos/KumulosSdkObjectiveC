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

extern NSString* const KSHttpMethodGet;
extern NSString* const KSHttpMethodPost;
extern NSString* const KSHttpMethodPut;
extern NSString* const KSHttpMethodDelete;

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

- (NSURLSessionDataTask*) sendRequest:(NSString* _Nonnull) method toPath:(NSString*) path withData:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionDataTask*) get:(NSString* _Nonnull) path onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionDataTask*) post:(NSString* _Nonnull) path data:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionDataTask*) put:(NSString* _Nonnull) path data:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;
- (NSURLSessionDataTask*) delete:(NSString* _Nonnull) path data:(id _Nullable) data onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure;

- (void) invalidateSessionCancelingTasks:(BOOL)cancelTasks;

@end
