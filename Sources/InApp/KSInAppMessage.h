//
//  KSInAppMessage.h
//  KumulosSDK iOS
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface KSInAppMessage : NSManagedObject

@property (nonatomic,strong) NSNumber* id;
@property (nonatomic,strong) NSDate* updatedAt;
@property (nonatomic) BOOL isRead;
@property (nonatomic,strong) NSString* presentedWhen;
@property (nonatomic,strong) NSDictionary* content;
@property (nonatomic,strong) NSDictionary* data;
@property (nonatomic,strong) NSDictionary* badgeConfig;
@property (nonatomic,strong) NSDictionary* inboxConfig;
@property (nonatomic,strong) NSDate* inboxFrom;
@property (nonatomic,strong) NSDate* inboxTo;
@property (nonatomic,strong) NSDate* openedAt;

@end
