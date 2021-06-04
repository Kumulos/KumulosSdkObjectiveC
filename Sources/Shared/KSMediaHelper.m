//
//  KSMediaHelper.m
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 03/06/2021.
//

#import "KSMediaHelper.h"
#import <Foundation/Foundation.h>

@implementation KSMediaHelper

NSString* const _Nonnull KSMediaResizerBaseUrl = @"https://i.app.delivery";

+ (NSURL *) getCompletePictureUrl:(NSString *)pictureUrl width:(NSUInteger)width {
    if ([[pictureUrl substringWithRange:NSMakeRange(0, 8)] isEqualToString:@"https://"]
        || [[pictureUrl substringWithRange:NSMakeRange(0, 7)] isEqualToString:@"http://"]){
        return [NSURL URLWithString:pictureUrl];
    }
    
    NSString* completeString = [NSString stringWithFormat:@"%@%@%lu%@%@", KSMediaResizerBaseUrl, @"/", (unsigned long) width, @"x/", pictureUrl];
    return [NSURL URLWithString:completeString];
}

@end
