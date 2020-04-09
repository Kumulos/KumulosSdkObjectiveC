//
//  KumulosNotificationService.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 05/12/2019.

#import "KumulosNotificationService.h"
#import "KSCategoryHelper.h"
#import "KSAnalyticsHelper.h"
#import "KSKeyValPersistenceHelper.h"
#import "KumulosUserDefaultsKeys.h"
#import "KumulosHelper.h"
#import "KumulosSharedEvents.h"
#import "KSAppGroupsHelper.h"

@implementation KumulosNotificationService

NSString* const _Nonnull KSMediaResizerBaseUrl = @"https://i.app.delivery";
static KSAnalyticsHelper* _Nullable analyticsHelper;

+ (void) didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    UNMutableNotificationContent *bestAttemptContent = [request.content mutableCopy];
    NSDictionary *userInfo = request.content.userInfo;
    
    if (![self validateUserInfo:userInfo]){
        return;
    }
   
    NSDictionary* custom = userInfo[@"custom"];
    NSDictionary* data = custom[@"a"];
    NSDictionary* msg = data[@"k.message"];
    NSDictionary* msgData = msg[@"data"];
    NSNumber* messageId = msgData[@"id"];
    
    if ([KSAppGroupsHelper isKumulosAppGroupDefined]){
        [self maybeSetBadge:bestAttemptContent userInfo:userInfo];
        [self trackDeliveredEvent:userInfo notificationId: messageId];
    }

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

+ (BOOL) validateUserInfo:(NSDictionary*)userInfo{
    return userInfo &&
            userInfo[@"custom"] &&
            userInfo[@"custom"][@"a"] &&
            userInfo[@"custom"][@"a"][@"k.message"] &&
            userInfo[@"custom"][@"a"][@"k.message"][@"data"] &&
            userInfo[@"custom"][@"a"][@"k.message"][@"data"][@"id"];
}

+ (void) maybeSetBadge:(UNMutableNotificationContent*)bestAttemptContent userInfo:(NSDictionary*)userInfo {
    NSDictionary* aps = userInfo[@"aps"];
    if (aps[@"content-available"] && [aps[@"content-available"] intValue] == 1){
        return;
    }
    
    NSNumber* newBadge = [KumulosHelper getBadgeFromUserInfo:userInfo];
    if (newBadge == nil){
        return;
    }
    
    bestAttemptContent.badge = newBadge;
    [KSKeyValPersistenceHelper setObject:newBadge forKey:KSPrefsKeyBadgeCount];
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
    NSString* apiKey = [KSKeyValPersistenceHelper objectForKey:KSPrefsKeyApiKey];
    NSString* secretKey = [KSKeyValPersistenceHelper objectForKey:KSPrefsKeySecretKey];
    
    if (apiKey == nil || secretKey == nil){
        NSLog(@"Extension: authorization credentials not present");
        return;
    }
    
    analyticsHelper = [[KSAnalyticsHelper alloc] initWithApiKey:apiKey withSecretKey:secretKey];
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
