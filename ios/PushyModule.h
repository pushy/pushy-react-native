#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <UserNotifications/UserNotifications.h>

@interface PushyObj : NSObject
- (void)application:(UIApplication * _Nonnull)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData * _Nonnull)deviceToken;
- (void)application:(UIApplication * _Nonnull)application didFailToRegisterForRemoteNotificationsWithError:(NSError * _Nonnull)error;
- (void)application:(UIApplication * _Nonnull)application didReceiveRemoteNotification:(NSDictionary * _Nonnull)userInfo;
- (void)application:(UIApplication * _Nonnull)application didReceiveRemoteNotification:(NSDictionary * _Nonnull)userInfo fetchCompletionHandler:(void (^ _Nonnull)(UIBackgroundFetchResult))completionHandler;
- (void)userNotificationCenter:(UNUserNotificationCenter* _Nonnull)center
       willPresentNotification:(UNNotification* _Nonnull)notification
         withCompletionHandler:(void (^_Nonnull)
       (UNNotificationPresentationOptions options))completionHandler;
@end

@interface PushyModule : RCTEventEmitter <RCTBridgeModule>
+ (PushyObj *_Nonnull)getSharedPushyInstance;
+ (void)didFinishLaunchingWithOptions:(NSDictionary *_Nonnull)launchOptions;
@end

