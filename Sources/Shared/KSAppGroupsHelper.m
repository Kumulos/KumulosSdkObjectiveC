//
//  KSAppGroupsHelper.m
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 26/03/2020.
//

#import <Foundation/Foundation.h>
#import "KSAppGroupsHelper.h"

@implementation KSAppGroupsHelper


+(BOOL) isKumulosAppGroupDefined {
    NSURL* containerUrl = [KSAppGroupsHelper getSharedContainerPath];
    return containerUrl != nil;
}

+(NSURL* _Nullable) getSharedContainerPath {
    return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[KSAppGroupsHelper getKumulosGroupName]];
}

+(NSString* _Nonnull) getKumulosGroupName {
    NSBundle* targetBundle = [NSBundle mainBundle];
    
    if ([targetBundle.bundleURL.pathExtension isEqualToString:@"appex"])
    {
        NSURL* url = targetBundle.bundleURL.URLByDeletingLastPathComponent.URLByDeletingLastPathComponent;
        
        NSBundle* mainBundle = [[NSBundle alloc] initWithURL:url];
        if (mainBundle != nil){
            targetBundle = mainBundle;
        }
        else{
            NSLog(@"AppGroupsHelper: Error, could not obtain main bundle from extension!");
        }
    }
    
    //FIXME: test correct group in app/in extension
    return [NSString stringWithFormat:@"group.%@.kumulos", targetBundle.bundleIdentifier];
}

@end
