//
//  NSString+URLEncoding.m
//  KumulosSDK
//
//  See: https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/
//

#import "NSString+URLEncoding.h"

@implementation NSString (URLEncoding)

- (nullable NSString *) urlEncodedStringForBody {
    NSString *unreserved = @"*-._ ";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    
    NSString *encoded = [self stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    encoded = [encoded stringByReplacingOccurrencesOfString:@" "
                                                 withString:@"+"];

    return encoded;
}


- (nullable NSString *) urlEncodedStringForUrl {
    NSString *unreserved = @"-._~";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    
    NSString *encoded = [self stringByAddingPercentEncodingWithAllowedCharacters:allowed];
  
    return encoded;
}

@end
