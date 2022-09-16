#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <UserNotifications/UserNotifications.h>

@interface PushyObj : NSObject <UIApplicationDelegate, UNUserNotificationCenterDelegate>
@end

@interface PushyModule : RCTEventEmitter <RCTBridgeModule>
+ (PushyObj *_Nonnull)getSharedPushyInstance;
+ (void)didFinishLaunchingWithOptions:(NSDictionary *_Nonnull)launchOptions;
@end

