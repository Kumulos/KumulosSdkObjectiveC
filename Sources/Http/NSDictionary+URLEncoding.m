//
//  NSDictionary+URLEncoding.m
//  KumulosSDK
//
//  Created by cgwyllie on 26/06/2018.
//

#import "NSDictionary+URLEncoding.h"
#import "NSString+URLEncoding.h"

@implementation NSDictionary (URLEncoding)

- (NSString *)stringFromEntriesWithUrlFormDataEncoding {
    NSMutableArray* pairs = [[NSMutableArray alloc] initWithCapacity:self.count];
    
    for (NSString* key in self) {
        NSString* valueString = [[NSString stringWithFormat:@"%@", self[key]] stringByAddingPercentEncodingForFormData:YES];
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", [key stringByAddingPercentEncodingForFormData:YES], valueString]];
    }
    
    return [pairs componentsJoinedByString:@"&"];
}

@end
