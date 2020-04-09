//
//  KSSessionHelper.h
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import "Shared/KSAnalyticsHelper.h"

@interface KSSessionHelper : NSObject

- (instancetype) initWithSessionIdleTimeout:(NSUInteger)timeout analyticsHelper:(KSAnalyticsHelper*) analyticsHelper;

@end
