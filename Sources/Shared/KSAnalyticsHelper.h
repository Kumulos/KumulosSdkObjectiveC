//
//  KSAnalyticsHelper.h
//  KumulosSDK iOS
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef void (^ _Nullable SyncCompletedBlock)(NSError* _Nullable error);

@interface KSAnalyticsHelper : NSObject

- (instancetype _Nullable) initWithApiKey:(NSString* _Nonnull)apiKey withSecretKey:(NSString* _Nonnull)secretKey;
- (void) trackEvent:(NSString* _Nonnull) eventType withProperties:(NSDictionary* _Nullable) properties;
- (void) trackEvent:(NSString* _Nonnull) eventType withProperties:(NSDictionary* _Nullable) properties flushingImmediately:(BOOL)flushImmediately;
- (void) trackEvent:(NSString* _Nonnull)eventType atTime:(NSDate* _Nonnull)happenedAt withProperties:(NSDictionary* _Nullable)properties flushingImmediately:(BOOL)flushImmediately onSyncComplete:(SyncCompletedBlock)onSyncComplete;


@end

@interface KSEventModel : NSManagedObject
@property (nonatomic,strong) NSString* _Nonnull uuid;
@property (nonatomic,strong) NSString* _Nonnull userIdentifier;
@property (nonatomic,strong) NSString* _Nonnull eventType;
@property (nonatomic,strong) NSNumber* _Nonnull happenedAt;
@property (nonatomic,strong) NSData* _Nullable properties;
@end
