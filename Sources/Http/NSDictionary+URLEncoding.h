//
//  NSDictionary+URLEncoding.h
//  KumulosSDK
//
//  Created by cgwyllie on 26/06/2018.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (URLEncoding)

- (NSString* _Nullable) stringFromEntriesWithUrlFormDataEncoding;

@end
