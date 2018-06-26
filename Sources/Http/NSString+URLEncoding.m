//
//  NSString+URLEncoding.m
//  KumulosSDK
//
//  See: https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/
//

#import "NSString+URLEncoding.h"

@implementation NSString (URLEncoding)

- (nullable NSString *)stringByAddingPercentEncodingForFormData:(BOOL)plusForSpace {
    NSString *unreserved = @"*-._";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    
    if (plusForSpace) {
        [allowed addCharactersInString:@" "];
    }
    
    NSString *encoded = [self stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    
    if (plusForSpace) {
        encoded = [encoded stringByReplacingOccurrencesOfString:@" "
                                                     withString:@"+"];
    }
    
    return encoded;
}

@end
