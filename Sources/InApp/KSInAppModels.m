//
//  KSInAppModels.m
//  KumulosSDK
//

#import "KSInAppModels.h"

@implementation KSInAppMessageEntity

@dynamic id;
@dynamic updatedAt;
@dynamic presentedWhen;
@dynamic content;
@dynamic data;
@dynamic badgeConfig;
@dynamic inboxConfig;
@dynamic inboxFrom;
@dynamic inboxTo;
@dynamic openedAt;

@end

@implementation KSInAppMessage

@synthesize id;
@synthesize updatedAt;
@synthesize presentedWhen;
@synthesize content;
@synthesize data;
@synthesize badgeConfig;
@synthesize inboxConfig;
@synthesize openedAt;

+ (instancetype)fromEntity:(KSInAppMessageEntity *)entity {
    KSInAppMessage* message = [KSInAppMessage new];

    message.id = entity.id;
    message.updatedAt = entity.updatedAt;
    message.content = entity.content;
    message.data = entity.data;
    message.badgeConfig = entity.badgeConfig;
    message.inboxConfig = entity.inboxConfig;
    message.openedAt = entity.openedAt;

    return message;
}

- (BOOL)isEqual:(id)other
{
    if (other && [other isKindOfClass:KSInAppMessage.class]) {
        return [self.id isEqualToNumber:((KSInAppMessage*)other).id];
    }

    return [super isEqual:other];
}

- (NSUInteger)hash
{
    return [self.id hash];
}

@end
