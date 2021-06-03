//
//  KSMediaHelper.h
//  KumulosSDK
//
//  Created by Vladislav Voicehovics on 03/06/2021.
//

#import <Foundation/Foundation.h>

@interface KSMediaHelper : NSObject

+ (NSURL *) getCompletePictureUrl:(NSString *)pictureUrl width:(NSUInteger)width;

@end
