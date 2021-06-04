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
@dynamic dismissedAt;
@dynamic expiresAt;
@dynamic readAt;
@dynamic sentAt;

- (BOOL) isAvailable {
    if (self.inboxFrom && [self.inboxFrom timeIntervalSinceNow] > 0) {
        return NO;
    } else if (self.inboxTo && [self.inboxTo timeIntervalSinceNow] < 0) {
        return NO;
    }

    return YES;
}

@end

@implementation KSInAppMessage

@synthesize id;
@synthesize updatedAt;
@synthesize presentedWhen;
@synthesize content;
@synthesize data;
@synthesize badgeConfig;
@synthesize inboxConfig;
@synthesize dismissedAt;
@synthesize readAt;
@synthesize sentAt;

+ (instancetype)fromEntity:(KSInAppMessageEntity *)entity {
    KSInAppMessage* message = [KSInAppMessage new];

    message.id = [entity.id copy];
    message.updatedAt = [entity.updatedAt copy];
    message.content = [entity.content copy];
    message.data = [entity.data copy];
    message.badgeConfig = [entity.badgeConfig copy];
    message.inboxConfig = [entity.inboxConfig copy];
    message.dismissedAt = [entity.dismissedAt copy];
    message.readAt = [entity.readAt copy];
    message.sentAt = [entity.sentAt copy];

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
