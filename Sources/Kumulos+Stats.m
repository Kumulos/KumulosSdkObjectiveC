//
//  Kumulos+Stats.m
//  KumulosSDK
//
//  Copyright © 2016 kumulos. All rights reserved.
//

#import "Kumulos+Stats.h"
#import "Kumulos+Protected.h"

#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
#import <sys/sysctl.h>
#else
#import <sys/utsname.h>
#import "KumulosEvents.h"
#endif

static const NSString* KSSdkVersion = @"2.3.0";

@implementation Kumulos (Stats)

- (void) statsSendInstallInfo {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        [self bundleAndSendInfo];
    });
}

- (void) bundleAndSendInfo {
    KSTargetType target;
    
    if (TargetTypeNotOverridden == self.config.targetType) {
        target = TargetTypeRelease;
#ifdef DEBUG
        target = TargetTypeDebug;
#endif
    }
    else {
        target = self.config.targetType;
    }

    NSDictionary *app = @{
                          @"bundle" : [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"],
                          @"version" : [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                          @"target"  : @(target)
                          };
    
    NSDictionary *sdk = self.config.sdkInfo;
    
    if (nil == sdk) {
        sdk = @{@"id" : @(SDKTypeObjC),
                @"version" : KSSdkVersion};
    }
    
    NSDictionary *runtime = self.config.runtimeInfo;
    NSDictionary *os;
    NSMutableDictionary *device = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *tzName = [timeZone name];
    
#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR && !TARGET_OS_IOS
    runtime = @{@"id" : @(RuntimeTypeNative),
                @"version" : [[NSProcessInfo processInfo] operatingSystemVersionString] };
    
    os = @{@"id" : @(OSTypeIDOSX),
           @"version" : [[NSProcessInfo processInfo] operatingSystemVersionString] };
    
    size_t size;
    sysctlbyname("hw.model", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.model", model, &size, NULL, 0);
    
    NSString* modelStr = [NSString stringWithUTF8String:model];
    
    [device setValuesForKeysWithDictionary:@{@"name" : modelStr,
                                            @"tz"   : tzName,
                                            @"isSimulator" : @(NO)}];
    
    
#else
    if (nil == runtime) {
        runtime = @{@"id" : @(RuntimeTypeNative),
                    @"version" : [[UIDevice currentDevice] systemVersion]};
    }
    
    os = @{@"id" : @(OSTypeIDiOS),
           @"version" : [[UIDevice currentDevice] systemVersion]};
    
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    BOOL isSimulator = NO;
#if TARGET_IPHONE_SIMULATOR
    isSimulator = YES;
#endif
    
    [device setValuesForKeysWithDictionary:@{@"name" : deviceName,
                                             @"tz"   : tzName,
                                             @"isSimulator":  @(isSimulator)}];
    
#endif
    
    if (NSLocale.preferredLanguages.count >= 1) {
        device[@"locale"] = NSLocale.preferredLanguages[0];
    }
    
    //final
    NSDictionary *jsonDict = @{@"app" : app,
                               @"sdk" : sdk,
                               @"runtime" : runtime,
                               @"os" : os,
                               @"device" : device};
    
#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR && !TARGET_OS_IOS
    NSString* path = [NSString stringWithFormat:@"/v1/app-installs/%@", [Kumulos installId]];
    
    [self.statsHttpClient put:path data:jsonDict onSuccess:^(NSHTTPURLResponse * _Nullable response, id  _Nullable decodedBody) {
        // Noop
    } onFailure:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        // Noop
    }];
#else
    [self.analyticsHelper trackEvent:KumulosEventCallHome withProperties:jsonDict];
#endif
    
}

@end
