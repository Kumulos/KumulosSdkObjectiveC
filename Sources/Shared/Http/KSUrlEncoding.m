//
//  KSUrlEncoding.m
//  KumulosSDK
//

#import "KSUrlEncoding.h"
#import "NSString+URLEncoding.h"

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

        fullKey = [[NSString stringWithFormat:@"%@[]", key] urlEncodedStringForBody];

        for (id item in arr) {
            if (!item) {
                continue;
            }
            
            [pairs addObjectsFromArray:KSUrlEncodedStringFromObjectWithParent(fullKey, item)];
        }

        return pairs;
    }

    return @[[NSString stringWithFormat:@"%@=%@",
              key.urlEncodedStringForBody,
              [NSString stringWithFormat:@"%@", obj].urlEncodedStringForBody]];
}

NSString* _Nonnull KSUrlEncodedStringFromDictionary(NSDictionary* _Nonnull obj) {
    NSArray* pairs = KSUrlEncodedStringFromObjectWithParent(nil, obj);
    
    return [pairs componentsJoinedByString:@"&"];
}

