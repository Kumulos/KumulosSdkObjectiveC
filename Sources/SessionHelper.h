//
//  SessionHelper.h
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 27/03/2020.
//

#import "AnalyticsHelper.h"

@interface SessionHelper : NSObject

- (instancetype) initWithSessionIdleTimeout:(NSUInteger)timeout analyticsHelper:(AnalyticsHelper*) analyticsHelper;

@end
