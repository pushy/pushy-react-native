#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface PushyObj : NSObject
- (void)application:(UIApplication * _Nonnull)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData * _Nonnull)deviceToken;
- (void)application:(UIApplication * _Nonnull)application didFailToRegisterForRemoteNotificationsWithError:(NSError * _Nonnull)error;
- (void)application:(UIApplication * _Nonnull)application didReceiveRemoteNotification:(NSDictionary * _Nonnull)userInfo;
- (void)application:(UIApplication * _Nonnull)application didReceiveRemoteNotification:(NSDictionary * _Nonnull)userInfo fetchCompletionHandler:(void (^ _Nonnull)(UIBackgroundFetchResult))completionHandler;
@end

@interface PushyModule : RCTEventEmitter <RCTBridgeModule>
+ (PushyObj *)getSharedPushyInstance;
+ (void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
@end

