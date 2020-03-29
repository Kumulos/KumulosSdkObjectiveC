//
//  KumulosNotificationService.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 05/12/2019.

#import "KumulosNotificationService.h"
#import "KSCategoryHelper.h"
#import "AnalyticsHelper.h"
#import "KSKeyValPersistenceHelper.h"
#import "KumulosUserDefaultsKeys.h"
#import "KumulosHelper.h"
#import "KumulosSharedEvents.h"

@implementation KumulosNotificationService

NSString* const _Nonnull KSMediaResizerBaseUrl = @"https://i.app.delivery";
static AnalyticsHelper* _Nullable analyticsHelper;

+ (void) didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    
    UNMutableNotificationContent *bestAttemptContent = [request.content mutableCopy];

    NSDictionary *userInfo = request.content.userInfo;
    NSDictionary* custom = userInfo[@"custom"];
    NSDictionary* data = custom[@"a"];
    NSDictionary* msg = data[@"k.message"];
    NSDictionary* msgData = msg[@"data"];
    NSNumber* messageId = msgData[@"id"];
    
    [self maybeSetBadge:bestAttemptContent userInfo: userInfo];
    [self trackDeliveredEvent:userInfo notificationId: messageId];
    
    if (data[@"k.buttons"]) {
        NSArray *buttons = data[@"k.buttons"];

        if (buttons != nil && [bestAttemptContent.categoryIdentifier isEqualToString:@""]) {
            [self addButtons:messageId withContent:bestAttemptContent withButtons:buttons];
        }
    }
    
    NSDictionary *attachments = userInfo[@"attachments"];
    NSString *pictureUrl = attachments == nil ? nil : attachments[@"pictureUrl"];
    
    if (pictureUrl == nil) {
        contentHandler(bestAttemptContent);
        return;
    }

    NSString *extension = [self getPictureExtension: pictureUrl];
    NSURL *url = [self getCompletePictureUrl: pictureUrl];
    [self loadAttachment:url
           withExtension:extension
       completionHandler:^(UNNotificationAttachment *attachment) {
           if (attachment) {
               bestAttemptContent.attachments = [NSArray arrayWithObject:attachment];
           }
           contentHandler(bestAttemptContent);
       }];
}


+ (void)maybeSetBadge:(UNMutableNotificationContent*)bestAttemptContent userInfo:(NSDictionary*)userInfo{
    NSDictionary* custom = userInfo[@"custom"];
    NSDictionary* aps = custom[@"aps"];
    
    NSNumber* incrementBy = custom[@"badge_inc"];
    NSNumber* badge = aps[@"badge"];
    
    if (badge == nil){
        return;
    }
    
    // Note in case of no cache, server sends the increment value in the badge field too, so works as badge = 0 + badge_inc
    NSNumber* newBadge = badge;
    NSNumber* currentBadgeCount = [KSKeyValPersistenceHelper objectForKey:KumulosBadgeCount];
    if (incrementBy != nil && currentBadgeCount != nil){
        newBadge = [NSNumber numberWithInt: currentBadgeCount.intValue + incrementBy.intValue];
    }
    
    bestAttemptContent.badge = newBadge;
    [KSKeyValPersistenceHelper setObject:newBadge forKey:KumulosBadgeCount];
}

+ (void)trackDeliveredEvent:(NSDictionary*)userInfo notificationId:(NSNumber*)notificationId{
    NSDictionary* aps = userInfo[@"aps"];
    if (aps[@"content-available"] && [aps[@"content-available"] intValue] == 1){
        return;
    }
    
    [self initializeAnalyticsHelper];
    if (analyticsHelper == nil){
        return;
    }
    
    NSDictionary* params = @{@"type": @(KS_MESSAGE_TYPE_PUSH), @"id": notificationId};
    [analyticsHelper trackEvent:KumulosEventMessageDelivered withProperties:params flushingImmediately:YES];
}

+ (void)initializeAnalyticsHelper{
    NSString* apiKey = [KSKeyValPersistenceHelper objectForKey:KumulosApiKey];
    NSString* secretKey = [KSKeyValPersistenceHelper objectForKey:KumulosSecretKey];
    
    if (apiKey == nil || secretKey == nil){
        NSLog(@"Extension: authorization credentials not present");
        return;
    }
    
    analyticsHelper = [[AnalyticsHelper alloc] initWithApiKey:apiKey withSecretKey:secretKey];
}

+ (void)addButtons:(NSNumber*)messageId withContent:(UNMutableNotificationContent*)content withButtons:(NSArray*) buttons {
    if (buttons.count == 0) {
        return;
    }
        
    NSMutableArray *actionArray = [NSMutableArray new];
    
    for (NSDictionary *button in buttons) {
        UNNotificationAction *action = [UNNotificationAction actionWithIdentifier:button[@"id"]
                                                                            title:button[@"text"]
                                                                          options:UNNotificationActionOptionForeground];

        [actionArray addObject: action];
    }
    
    NSString *categoryIdentifier = [KSCategoryHelper getCategoryIdForMessageId:messageId];
    
    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:categoryIdentifier
                                                                              actions:actionArray
                                                                    intentIdentifiers:@[]
                                                                              options:UNNotificationCategoryOptionCustomDismissAction];
    
    [KSCategoryHelper registerCategory: category];
    
    content.categoryIdentifier = categoryIdentifier;
}

+ (NSString * _Nullable) getPictureExtension:(NSString *) pictureUrl {
    NSString *pictureExtension = [pictureUrl pathExtension];
    if ([pictureExtension isEqualToString:@""]){
       return nil;
    }
 
    return [ @"." stringByAppendingString:pictureExtension];
}

+ (NSURL *) getCompletePictureUrl:(NSString *)pictureUrl {
    if ([[pictureUrl substringWithRange:NSMakeRange(0, 8)] isEqualToString:@"https://"]
        || [[pictureUrl substringWithRange:NSMakeRange(0, 7)] isEqualToString:@"http://"]){
        return [NSURL URLWithString:pictureUrl];
    }

    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    NSInteger num = (NSInteger) (floor(width));

    NSString *completeString = [NSString stringWithFormat:@"%@%@%ld%@%@", KSMediaResizerBaseUrl, @"/", (long) num, @"x/", pictureUrl];
    return [NSURL URLWithString:completeString];
}

+ (void)loadAttachment:(NSURL *)url withExtension:(NSString * _Nullable)pictureExtension completionHandler:(void(^)(UNNotificationAttachment *))completionHandler API_AVAILABLE(ios(10.0)){
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    [[session downloadTaskWithURL:url
                completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
                    if (error != nil) {
                        NSLog(@"NotificationServiceExtension: %@", error.localizedDescription);
                        completionHandler(nil);
                        return;
                    }
        
                    NSString * finalExt = pictureExtension;
                    if (finalExt == nil){
                        finalExt = [self getPictureExtension: [response suggestedFilename]];
                        if (finalExt == nil){
                            completionHandler(nil);
                            return;
                        }
                    }

                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSURL *localURL = [NSURL fileURLWithPath:[temporaryFileLocation.path stringByAppendingString:finalExt]];
                    [fileManager moveItemAtURL:temporaryFileLocation toURL:localURL error:&error];

                    NSError *attachmentError = nil;
                    UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attachmentError];
                    if (attachmentError) {
                        NSLog(@"NotificationServiceExtension: attachment error: %@", attachmentError.localizedDescription);
                    }

                    completionHandler(attachment);
                }] resume];
}

@end
