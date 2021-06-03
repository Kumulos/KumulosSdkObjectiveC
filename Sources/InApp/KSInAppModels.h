//
//  KSInAppModels.h
//  KumulosSDK iOS
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface KSInAppMessageEntity : NSManagedObject

@property (nonatomic,strong) NSNumber* id;
@property (nonatomic,strong) NSDate* updatedAt;
@property (nonatomic,strong) NSString* presentedWhen;
@property (nonatomic,strong) NSDictionary* content;
@property (nonatomic,strong) NSDictionary* data;
@property (nonatomic,strong) NSDictionary* badgeConfig;
@property (nonatomic,strong) NSDictionary* inboxConfig;
@property (nonatomic,strong) NSDate* inboxFrom;
@property (nonatomic,strong) NSDate* inboxTo;
@property (nonatomic,strong) NSDate* dismissedAt;
@property (nonatomic,strong) NSDate* expiresAt;
@property (nonatomic,strong) NSDate* readAt;
@property (nonatomic,strong) NSDate* sentAt;

@end

@interface KSInAppMessage : NSObject

@property (nonatomic,strong) NSNumber* id;
@property (nonatomic,strong) NSDate* updatedAt;
@property (nonatomic,strong) NSString* presentedWhen;
@property (nonatomic,strong) NSDictionary* content;
@property (nonatomic,strong) NSDictionary* data;
@property (nonatomic,strong) NSDictionary* badgeConfig;
@property (nonatomic,strong) NSDictionary* inboxConfig;
@property (nonatomic,strong) NSDate* dismissedAt;
@property (nonatomic,strong) NSDate* readAt;
@property (nonatomic,strong) NSDate* sentAt;

+ (instancetype) fromEntity:(KSInAppMessageEntity*)entity;

- (BOOL) isEqual:(id)other;
- (NSUInteger) hash;

@end
