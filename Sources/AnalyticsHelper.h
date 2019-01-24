//
//  AnalyticsHelper.h
//  KumulosSDK iOS
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Kumulos.h"

@interface AnalyticsHelper : NSObject

- (instancetype _Nullable) initWithKumulos:(Kumulos* _Nonnull) kumulos;
- (void) trackEvent:(NSString* _Nonnull) eventType withProperties:(NSDictionary* _Nullable) properties;
- (void) trackEvent:(NSString* _Nonnull) eventType withProperties:(NSDictionary* _Nullable) properties flushingImmediately:(BOOL)flushImmediately;

@end

@interface KSEventModel : NSManagedObject
@property (nonatomic) int64_t identifier;

@property (nonatomic,strong) NSString* uuid;
@property (nonatomic,strong) NSString* eventType;
@property (nonatomic,strong) NSNumber* happenedAt;
@property (nonatomic,strong) NSData* properties;
@end
