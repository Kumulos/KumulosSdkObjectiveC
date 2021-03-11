//
//  KSPendingNotification.m
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 10/03/2021.
//

#import <Foundation/Foundation.h>

#import "KSPendingNotification.h"

@implementation KSPendingNotification

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithId:(NSNumber* _Nonnull)notificationId dismissedAt:(NSDate*)dismissedAt identifier:(NSString*)identifier {
    if (self = [super init]) {
        self->_notificationId = notificationId;
        self->_dismissedAt = dismissedAt;
        self->_identifier = identifier;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.notificationId forKey:@"notificationId"];
    [encoder encodeObject:self.dismissedAt forKey:@"dismissedAt"];
    [encoder encodeObject:self.identifier forKey:@"identifier"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.notificationId = [decoder decodeObjectOfClass:[NSNumber class] forKey:@"notificationId"];
        self.dismissedAt = [decoder decodeObjectOfClass:[NSDate class] forKey:@"dismissedAt"];
        self.identifier = [decoder decodeObjectOfClass:[NSString class] forKey:@"identifier"];
    }

    return self;
}

@end
