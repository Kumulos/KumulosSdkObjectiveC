//
//  KSAppGroupsHelper.h
//  KumulosSDK iOS
//
//  Created by Vladislav Voicehovics on 26/03/2020.
//



@interface KSAppGroupsHelper : NSObject

+(BOOL) isKumulosAppGroupDefined;
+(NSURL* _Nullable) getSharedContainerPath;
+(NSString* _Nonnull) getKumulosGroupName;

@end






