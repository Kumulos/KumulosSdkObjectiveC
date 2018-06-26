//
//  NSString+URLEncoding.h
//  KumulosSDK
//
//  See: https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/
//

#import <Foundation/Foundation.h>

@interface NSString (URLEncoding)

- (nullable NSString *)stringByAddingPercentEncodingForFormData:(BOOL)plusForSpace;

@end
