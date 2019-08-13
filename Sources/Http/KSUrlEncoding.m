//
//  KSUrlEncoding.m
//  KumulosSDK
//

#import "KSUrlEncoding.h"
#import "NSString+URLEncoding.m"

// Based on recursive encoding from AFNetworking serializer
NSArray* _Nonnull KSUrlEncodedStringFromObjectWithParent(NSString* _Nullable key, id obj) {
    NSMutableArray* pairs = [NSMutableArray array];
    NSString* fullKey;
    
    if ([obj isKindOfClass:NSDictionary.class]) {
        NSDictionary* dict = (NSDictionary*) obj;
        
        for (NSString* childKey in dict) {
            id val = obj[childKey];
            
            if (!val) {
                continue;
            }
            
            fullKey = key ? [NSString stringWithFormat:@"%@[%@]", key, childKey] : childKey;
            
            [pairs addObjectsFromArray:KSUrlEncodedStringFromObjectWithParent(fullKey, val)];
        }

        return pairs;
    }
    else if ([obj isKindOfClass:NSArray.class]) {
        NSArray* arr = (NSArray*) obj;

        fullKey = [[NSString stringWithFormat:@"%@[]", key] urlEncodedString];

        for (id item in arr) {
            if (!item) {
                continue;
            }
            
            [pairs addObjectsFromArray:KSUrlEncodedStringFromObjectWithParent(fullKey, item)];
        }

        return pairs;
    }

    return @[[NSString stringWithFormat:@"%@=%@",
              key.urlEncodedString,
              [NSString stringWithFormat:@"%@", obj].urlEncodedString]];
}

NSString* _Nonnull KSUrlEncodedStringFromDictionary(NSDictionary* _Nonnull obj) {
    NSArray* pairs = KSUrlEncodedStringFromObjectWithParent(nil, obj);
    
    return [pairs componentsJoinedByString:@"&"];
}

