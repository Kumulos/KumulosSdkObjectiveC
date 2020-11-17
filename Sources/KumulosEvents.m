//
//  KumulosEvents.m
//  KumulosSDK
//

#import "KumulosEvents.h"

NSString* const KumulosEventForeground = @"k.fg";
NSString* const KumulosEventBackground = @"k.bg";
NSString* const KumulosEventCallHome = @"k.stats.installTracked";
NSString* const KumulosEventUserAssociated = @"k.stats.userAssociated";
NSString* const KumulosEventUserAssociationCleared = @"k.stats.userAssociationCleared";
NSString* const KumulosEventPushRegistered = @"k.push.deviceRegistered";
NSString* const KumulosEventBeaconEnteredProximity = @"k.engage.beaconEnteredProximity";
NSString* const KumulosEventLocationUpdated = @"k.engage.locationUpdated";
NSString* const KumulosEventDeviceUnsubscribed = @"k.push.deviceUnsubscribed";
NSString* const KumulosEventInAppConsentChanged = @"k.inApp.statusUpdated";
NSString* const KumulosEventMessageOpened = @"k.message.opened";
NSString* const KumulosEventMessageDismissed = @"k.message.dismissed";
NSString* const KumulosEventMessageDeletedFromInbox = @"k.message.inbox.deleted";
NSString* const KumulosEventDeepLinkMatched = @"k.deepLink.matched";
