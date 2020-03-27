//
//  AnalyticsHelper.h
//  KumulosSDK iOS
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Kumulos.h"

typedef void (^ _Nullable SyncCompletedBlock)(NSError* _Nullable error);

@interface AnalyticsHelper : NSObject

- (instancetype _Nullable) initWithKumulos:(Kumulos* _Nonnull) kumulos;
- (void) trackEvent:(NSString* _Nonnull) eventType withProperties:(NSDictionary* _Nullable) properties;
- (void) trackEvent:(NSString* _Nonnull) eventType withProperties:(NSDictionary* _Nullable) properties flushingImmediately:(BOOL)flushImmediately;
- (void) trackEvent:(NSString *)eventType atTime:(NSDate *)happenedAt withProperties:(NSDictionary *)properties flushingImmediately:(BOOL)flushImmediately onSyncComplete:(SyncCompletedBlock)onSyncComplete;


@end

@interface KSEventModel : NSManagedObject
@property (nonatomic,strong) NSString* _Nonnull uuid;
@property (nonatomic,strong) NSString* _Nonnull userIdentifier;
@property (nonatomic,strong) NSString* _Nonnull eventType;
@property (nonatomic,strong) NSNumber* _Nonnull happenedAt;
@property (nonatomic,strong) NSData* _Nullable properties;
@end
