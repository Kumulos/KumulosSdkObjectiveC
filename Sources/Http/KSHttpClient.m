
//
//  HttpClient.m
//  KumulosSDK
//
//  Created by cgwyllie on 25/06/2018.
//

#import "Kumulos.h"
#import "KSHttpClient.h"
#import "NSDictionary+URLEncoding.h"

NSString* const KSHttpMethodGet = @"GET";
NSString* const KSHttpMethodPost = @"POST";
NSString* const KSHttpMethodPut = @"PUT";
NSString* const KSHttpMethodDelete = @"DELETE";

@interface KSHttpClient ()

@property (nonatomic) NSString* authHeader;

@end

@implementation KSHttpClient

#pragma mark - Initializers & configs

- (instancetype)initWithBaseUrl:(NSString *)baseUrl requestBodyFormat:(KSHttpDataFormat)requestFormat responseBodyFormat:(KSHttpDataFormat)responseFormat {
    if (self = [super init]) {
        self->_baseUrl = [NSURL URLWithString:baseUrl];
        self->_requestBodyFormat = requestFormat;
        self->_responseBodyFormat = responseFormat;
        self->_authHeader = nil;
        
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        if (KSHttpDataFormatJson == responseFormat) {
            config.HTTPAdditionalHeaders = @{@"Accept": @"application/json"};
        }
        
        self->_urlSession = [NSURLSession sessionWithConfiguration:config];
    }
    
    return self;
}

- (void)setBasicAuthWithUser:(NSString *)user andPassword:(NSString *)password {
    NSString* creds = [NSString stringWithFormat:@"%@:%@", user, password];
    
    NSData* dataCreds = [creds dataUsingEncoding:NSUTF8StringEncoding];
    NSString* base64Creds = [dataCreds base64EncodedStringWithOptions:0];
    
    self.authHeader = [NSString stringWithFormat:@"Basic %@", base64Creds];
}

- (void)invalidateSessionCancelingTasks:(BOOL)cancelTasks {
    if (cancelTasks) {
        [self.urlSession invalidateAndCancel];
    }
    else {
        [self.urlSession finishTasksAndInvalidate];
    }
}

#pragma mark - HTTP methods

- (NSURLSessionDataTask *) sendRequest:(NSString *)method toPath:(NSString *)path withData:(id) data onSuccess:(KSHttpSuccessBlock)success onFailure:(KSHttpFailureBlock)failure {
    NSURLRequest* request = [self newRequestToPath:path withMethod:method body:data];
    
    return [self sendRequest:request onSuccess:success onFailure:failure];
}

- (NSURLSessionDataTask *)get:(NSString *)path onSuccess:(KSHttpSuccessBlock)success onFailure:(KSHttpFailureBlock)failure {
    return [self sendRequest:KSHttpMethodGet toPath:path withData:nil onSuccess:success onFailure:failure];
}

- (NSURLSessionDataTask *)post:(NSString *)path data:(id)data onSuccess:(KSHttpSuccessBlock)success onFailure:(KSHttpFailureBlock)failure {
    return [self sendRequest:KSHttpMethodPost toPath:path withData:data onSuccess:success onFailure:failure];
}

- (NSURLSessionDataTask *)put:(NSString *)path data:(id)data onSuccess:(KSHttpSuccessBlock)success onFailure:(KSHttpFailureBlock)failure {
    return [self sendRequest:KSHttpMethodPut toPath:path withData:data onSuccess:success onFailure:failure];
}

- (NSURLSessionDataTask *)delete:(NSString *)path data:(id)data onSuccess:(KSHttpSuccessBlock)success onFailure:(KSHttpFailureBlock)failure {
    return [self sendRequest:KSHttpMethodDelete toPath:path withData:data onSuccess:success onFailure:failure];
}

#pragma mark - Helpers

- (NSMutableURLRequest* _Nullable) newRequestToPath:(NSString* _Nonnull) path withMethod:(NSString* _Nonnull) method body:(id _Nullable) body {
    NSURL* url = [NSURL URLWithString:path relativeToURL:self.baseUrl];
    NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    urlRequest.HTTPMethod = method;
    
    if (nil != self.authHeader) {
        [urlRequest setValue:self.authHeader forHTTPHeaderField:@"Authorization"];
    }
    
    switch (self.requestBodyFormat) {
        case KSHttpDataFormatJson:
            [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            break;
        
        case KSHttpDataFormatWwwUrlEncoded:
            [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            break;

        default:
            NSLog(@"No header set for request format");
            break;
    }
    
    if (nil != body) {
        NSData* encodedBody = [self encodeBody:body];
        
        if (nil != encodedBody) {
            urlRequest.HTTPBody = encodedBody;
        }
    }
    
    return urlRequest;
}

- (NSData*) encodeBody:(id _Nullable) body {
    NSData* encodedData = nil;
    NSError* err = nil;
    
    switch (self.requestBodyFormat) {
        case KSHttpDataFormatJson:
            if (![NSJSONSerialization isValidJSONObject:body]) {
                return nil;
            }
            
            encodedData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
            break;
        
        case KSHttpDataFormatWwwUrlEncoded:
            if ([body respondsToSelector:@selector(stringFromEntriesWithUrlFormDataEncoding)]) {
                encodedData = [[body stringFromEntriesWithUrlFormDataEncoding] dataUsingEncoding:NSUTF8StringEncoding];
            }
            break;
            
        default:
            NSLog(@"No body encoder defined for format");
            break;
    }
    
    if (nil != err) {
        return nil;
    }
    
    return encodedData;
}

- (id _Nullable) decodeBody:(NSData*) data {
    if (0 == data.length) {
        return nil;
    }

    id decodedBody = nil;
    NSError* err = nil;
    
    switch (self.responseBodyFormat) {
        case KSHttpDataFormatJson:
            decodedBody = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            break;
        
        case KSHttpDataFormatPList:
            decodedBody = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:&err];
            break;

        default:
            NSLog(@"No body decoder defined for format");
            break;
    }
    
    if (nil != err) {
        return nil;
    }
    
    return decodedBody;
}

- (NSURLSessionDataTask*) sendRequest:(NSURLRequest*) request onSuccess:(KSHttpSuccessBlock) success onFailure:(KSHttpFailureBlock) failure {
    NSURLSessionDataTask* task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse* httpResponse = nil;
        
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSError* castError = [NSError
                                  errorWithDomain:KSErrorDomain
                                  code:KSErrorCodeUnknownError
                                  userInfo:@{NSLocalizedDescriptionKey: @"Unable to case HTTP response from NSURLResponse"}];

            failure(nil, castError);
            return;
        }

        httpResponse = (NSHTTPURLResponse*) response;
        
        if (error) {
            failure(httpResponse, error);
            return;
        }
        
        id decodedBody = nil;
        
        if (nil != data) {
            decodedBody = [self decodeBody:data];
        }
        
        if (httpResponse.statusCode > 299) {
            NSError* statusError = [NSError
                                    errorWithDomain:KSErrorDomain
                                    code:KSErrorCodeHttpBadStatus
                                    userInfo:decodedBody];
            
            failure(httpResponse, statusError);
            return;
        }
        
        success(httpResponse, decodedBody);
    }];
    
    [task resume];
    
    return task;
}

@end
