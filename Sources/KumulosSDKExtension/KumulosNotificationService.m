//
//  KumulosNotificationService.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 05/12/2019.

#import "KumulosNotificationService.h"


@implementation KumulosNotificationService

NSString* const _Nonnull KSMediaResizerBaseUrl = @"https://i.app.delivery";

+ (void) didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    
    UNMutableNotificationContent *bestAttemptContent = [request.content mutableCopy];

    NSDictionary *userInfo = request.content.userInfo;
    NSDictionary *attachments = userInfo == nil ? nil : userInfo[@"attachments"];
    NSString *pictureUrl = attachments == nil ? nil : attachments[@"pictureUrl"];
    
    if (pictureUrl == nil) {
        contentHandler(bestAttemptContent);
        return;
    }

    NSString *extension = [self getPictureExtension: pictureUrl];
    NSURL *url = [self getCompletePictureUrl: pictureUrl];
    [self loadAttachment:url withExtension:extension
                   completionHandler:^(UNNotificationAttachment *attachment) {
                       if (attachment) {
                           bestAttemptContent.attachments = [NSArray arrayWithObject:attachment];
                       }
                       contentHandler(bestAttemptContent);
                   }];
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
