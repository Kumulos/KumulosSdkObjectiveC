//
//  Kumulos+Kumulos_Analytics.m
//  KumulosSDK iOS
//

#import "Kumulos+Analytics.h"
#import "Kumulos+Protected.h"

@implementation Kumulos (Analytics)

- (void) trackEvent:(NSString *)eventType withProperties:(NSDictionary *)properties {
    if ([eventType isEqualToString:@""] || ![NSJSONSerialization isValidJSONObject:properties]) {
        NSLog(@"Ignoring invalid event with empty type or non-serializable properties");
    }
    
    [self.analyticsContext performBlock:^{
        NSManagedObjectContext* context = self.analyticsContext;
        
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
        
        if (!entity) {
            return;
        }
        
        NSManagedObject* event = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
        
        if (!event) {
            return;
        }
        
        NSError* err = nil;
        
        NSNumber* happenedAt = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
        NSString* uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
        NSData* propsJson = [NSJSONSerialization dataWithJSONObject:properties options:0 error:&err];
        
        if (err) {
            NSLog(@"Failed to encode properties, properties will be nil");
            propsJson = nil;
            err = nil;
        }
        
        [event setValue:uuid forKey:@"uuid"];
        [event setValue:happenedAt forKey:@"happenedAt"];
        [event setValue:eventType forKey:@"eventType"];
        [event setValue:propsJson forKey:@"properties"];
        
        [context save:&err];
        
        if (err) {
            NSLog(@"Failed to record event: %@", err);
        }
    }];
}

@end
