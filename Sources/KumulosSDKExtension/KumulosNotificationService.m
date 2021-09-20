//
//  KumulosNotificationService.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 05/12/2019.

#import "KumulosNotificationService.h"
#import "KSCategoryHelper.h"
#import "../Shared/KSAnalyticsHelper.h"
#import "../Shared/KSKeyValPersistenceHelper.h"
#import "../Shared/KumulosUserDefaultsKeys.h"
#import "../Shared/KumulosHelper.h"
#import "../Shared/KumulosSharedEvents.h"
#import "../Shared/KSAppGroupsHelper.h"
#import "../Shared/KSPendingNotificationHelper.h"
#import "../Shared/KSMediaHelper.h"

@implementation KumulosNotificationService

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
    
    if ([bestAttemptContent.categoryIdentifier isEqualToString:@""]){
        NSMutableArray* actionButtons = [self getButtons:userInfo bestAttemptContent:bestAttemptContent];
        [self addCategory:bestAttemptContent actionArray:actionButtons messageId:messageId];
    }
    
    dispatch_group_t dispatchGroup = dispatch_group_create();
    [self maybeAddImageAttachment:(dispatch_group_t)dispatchGroup userInfo:(NSDictionary*)userInfo bestAttemptContent:(UNMutableNotificationContent*)bestAttemptContent];
    
    if ([KSAppGroupsHelper isKumulosAppGroupDefined]){
        [self maybeSetBadge:bestAttemptContent userInfo:userInfo];
        [self trackDeliveredEvent:dispatchGroup userInfo:userInfo notificationId: messageId];
        
        [KSPendingNotificationHelper add:[[KSPendingNotification alloc] initWithId:messageId dismissedAt:[NSDate date] identifier:request.identifier]];
    }
    
    
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        contentHandler(bestAttemptContent);
    });
}

+ (BOOL) validateUserInfo:(NSDictionary*)userInfo{
    return userInfo &&
            userInfo[@"custom"] &&
            userInfo[@"custom"][@"a"] &&
            userInfo[@"custom"][@"a"][@"k.message"] &&
            userInfo[@"custom"][@"a"][@"k.message"][@"data"] &&
            userInfo[@"custom"][@"a"][@"k.message"][@"data"][@"id"];
}


+ (NSMutableArray*) getButtons:(NSDictionary *)userInfo bestAttemptContent:(UNMutableNotificationContent *)bestAttemptContent {
    NSMutableArray* actionArray = [NSMutableArray new];
    
    NSDictionary* custom = userInfo[@"custom"];
    NSDictionary* data = custom[@"a"];
   
    NSArray* buttons = data[@"k.buttons"];
    if (buttons == nil || buttons.count == 0){
        return actionArray;
    }
    
    for (NSDictionary* button in buttons) {
        if (@available(iOS 15.0, *)) {
            UNNotificationActionIcon* icon = [self getButtonIcon:button];
            UNNotificationAction* action = [UNNotificationAction actionWithIdentifier:button[@"id"]
                                                                                title:button[@"text"]
                                                                              options:UNNotificationActionOptionForeground
                                                                                 icon: icon];
            [actionArray addObject: action];
        } else {
            UNNotificationAction* action = [UNNotificationAction actionWithIdentifier:button[@"id"]
                                                                                title:button[@"text"]
                                                                              options:UNNotificationActionOptionForeground];
            [actionArray addObject: action];
        }
    }
    
    return actionArray;
}

+ (UNNotificationActionIcon*) getButtonIcon:(NSDictionary*) buttonInfo{
    NSDictionary* iconDict = buttonInfo == nil ? nil : buttonInfo[@"icon"];
    if (iconDict == nil) {
        return nil;
    }
    
    NSString* type = iconDict[@"type"];
    NSString* icon = iconDict[@"icon"];
    
    if (type == nil || icon == nil) {
        return nil;
    }
    
    if ([type  isEqual: @"system"]) {
        return [UNNotificationActionIcon iconWithSystemImageName: type];
    }
    
    return [UNNotificationActionIcon iconWithTemplateImageName: type];
}
    
+ (void) addCategory:(UNMutableNotificationContent *)bestAttemptContent actionArray:(NSMutableArray*) actionArray messageId:(NSNumber*) messageId{
  
    NSString* categoryIdentifier = [KSCategoryHelper getCategoryIdForMessageId:messageId];

    
    UNNotificationCategory* category = [UNNotificationCategory categoryWithIdentifier:categoryIdentifier
                                                                              actions:actionArray
                                                                    intentIdentifiers:@[]
                                                                              options:UNNotificationCategoryOptionCustomDismissAction];
    [KSCategoryHelper registerCategory: category];
    bestAttemptContent.categoryIdentifier = categoryIdentifier;
}

+ (void) maybeAddImageAttachment:(dispatch_group_t)dispatchGroup userInfo:(NSDictionary*)userInfo bestAttemptContent:(UNMutableNotificationContent*)bestAttemptContent {

    NSDictionary* attachments = userInfo[@"attachments"];
    NSString* pictureUrl = attachments == nil ? nil : attachments[@"pictureUrl"];
    if (pictureUrl == nil){
        return;
    }
    
    NSString* extension = [self getPictureExtension: pictureUrl];
    NSURL* url = [KSMediaHelper getCompletePictureUrl:pictureUrl width:(NSUInteger) (floor(UIScreen.mainScreen.bounds.size.width))];
    
    dispatch_group_enter(dispatchGroup);
   
    [self loadAttachment:url
           withExtension:extension
       completionHandler:^(UNNotificationAttachment *attachment) {
           if (attachment) {
               bestAttemptContent.attachments = [NSArray arrayWithObject:attachment];
           }
           
           dispatch_group_leave(dispatchGroup);
       }];
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

+ (void)trackDeliveredEvent:(dispatch_group_t)dispatchGroup userInfo:(NSDictionary*)userInfo notificationId:(NSNumber*)notificationId{
    NSDictionary* aps = userInfo[@"aps"];
    if (aps[@"content-available"] && [aps[@"content-available"] intValue] == 1){
        return;
    }
    
    [self initializeAnalyticsHelper];
    if (analyticsHelper == nil){
        return;
    }
    
    NSDictionary* params = @{@"type": @(KS_MESSAGE_TYPE_PUSH), @"id": notificationId};
    
    dispatch_group_enter(dispatchGroup);
    dispatch_semaphore_t syncBarrier = dispatch_semaphore_create(0);
    
    [analyticsHelper trackEvent:KumulosEventMessageDelivered atTime:[NSDate date] withProperties:params flushingImmediately:YES onSyncComplete:^(NSError* err){
        dispatch_semaphore_signal(syncBarrier);
    }];
    
    dispatch_semaphore_wait(syncBarrier, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)));
    dispatch_group_leave(dispatchGroup);
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

+ (NSString * _Nullable) getPictureExtension:(NSString *) pictureUrl {
    NSString* pictureExtension = [pictureUrl pathExtension];
    if ([pictureExtension isEqualToString:@""]){
       return nil;
    }
 
    return [ @"." stringByAppendingString:pictureExtension];
}

+ (void)loadAttachment:(NSURL *)url withExtension:(NSString * _Nullable)pictureExtension completionHandler:(void(^)(UNNotificationAttachment *))completionHandler API_AVAILABLE(ios(10.0)){
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    [[session downloadTaskWithURL:url
                completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
                    if (error != nil) {
                        NSLog(@"NotificationServiceExtension: %@", error.localizedDescription);
                        completionHandler(nil);
                        return;
                    }
        
                    NSString* finalExt = pictureExtension;
                    if (finalExt == nil){
                        finalExt = [self getPictureExtension: [response suggestedFilename]];
                        if (finalExt == nil){
                            completionHandler(nil);
                            return;
                        }
                    }

                    NSFileManager* fileManager = [NSFileManager defaultManager];
                    NSURL* localURL = [NSURL fileURLWithPath:[temporaryFileLocation.path stringByAppendingString:finalExt]];
                    [fileManager moveItemAtURL:temporaryFileLocation toURL:localURL error:&error];

                    NSError* attachmentError = nil;
                    UNNotificationAttachment* attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attachmentError];
                    if (attachmentError) {
                        NSLog(@"NotificationServiceExtension: attachment error: %@", attachmentError.localizedDescription);
                    }

                    completionHandler(attachment);
                }] resume];
}

@end
