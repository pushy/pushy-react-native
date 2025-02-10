#import "PushyModule.h"
#import <UserNotifications/UserNotifications.h>

@import Pushy;
@implementation PushyModule

RCT_EXPORT_MODULE();

Pushy *pushy;
NSDictionary *coldStartNotification;

- (Pushy *) getPushyInstance
{
    // Pushy instance singleton
    if (!pushy) {
        pushy = [[Pushy alloc]init:[UIApplication sharedApplication]];
    }
    
    return pushy;
}

+ (Pushy *) getSharedPushyInstance
{
    // Pushy instance singleton
    if (!pushy) {
        pushy = [[Pushy alloc]init:[UIApplication sharedApplication]];
    }
    
    return pushy;
}

+ (void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Got options?
    if (launchOptions != nil) {
        // Get remote notification (may be nil)
        NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        
        // Save cold-start notification for later when Pushy.listen() is called
        if (remoteNotification != nil) {
            coldStartNotification = remoteNotification;
        }
    }
}

RCT_EXPORT_METHOD(setLocalPushConnectivityConfig:(NSString * _Nullable)endpoint port:(NSNumber * _Nullable)port keepAlive:(NSNumber * _Nullable)keepAlive ssids:(NSArray<NSString *> * _Nullable)ssids) {
    // iOS 14 and newer
    if (@available(iOS 14.0, *)) {
        // Configure Local Push Connectivity
        [PushyMQTT setLocalPushConnectivityConfigWithEndpoint: endpoint port: port keepAlive: keepAlive ssids: ssids];
    }
}

RCT_EXPORT_METHOD(listen)
{
    // Run on main thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        // Handle push notifications
        [[self getPushyInstance] setNotificationHandler:^(NSDictionary *data, void (^completionHandler)(UIBackgroundFetchResult)) {
            // Print notification payload data
            NSLog(@"Received notification: %@", data);
        
            // Emit RCT event with notification payload dictionary
            [self sendEventWithName:@"Notification" body:data];
        
            // Check if app was inactive (this means notification was clicked)
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive) {
                // Emit RCT notification click event with notification payload dictionary
                [self sendEventWithName:@"NotificationClick" body:data];
            }
        
            // Call the completion handler immediately on behalf of the app
            completionHandler(UIBackgroundFetchResultNewData);
        }];
        
        // Handle iOS in-app banner notification tap event (iOS 10+)
        [[self getPushyInstance] setNotificationClickListener:^(NSDictionary *data) {
            // Print event info & notification payload data
            NSLog(@"Notification click: %@", data);
            
            // Emit RTC notification click event with payload dictionary
            [self sendEventWithName:@"NotificationClick" body:data];
        }];
    
        // Check for cold start notification (from didFinishLaunchingWithOptions)
        if (coldStartNotification != nil) {
            // Emit RCT event with notification payload dictionary
            [self sendEventWithName:@"Notification" body:coldStartNotification];
        
            // Cold start notifications were always clicked by the user
            [self sendEventWithName:@"NotificationClick" body:coldStartNotification];

            // Clear cold start notification obj to avoid re-delivery on app reload
            coldStartNotification = nil;
        }
    });
}

RCT_EXPORT_METHOD(setCriticalAlertOption)
{
    // Define critical alert notification options
    UNAuthorizationOptions options = UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionCriticalAlert;
    
    // Set custom options
    [[self getPushyInstance] setCustomNotificationOptions: options];
}

RCT_EXPORT_METHOD(register:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    // Keep track of promise resolve/reject invocation
    __block BOOL resolved = NO;
    
    // Run on main thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        // Register the device for push notifications
        [[self getPushyInstance] register:^(NSError *error, NSString* deviceToken) {
            // Handle registration errors
            if (error != nil) {
                // Avoid resolving if did so in the past
                if (!resolved){
                    resolved = YES;
                
                    // Reject promise with error
                    reject(@"Error", [NSString stringWithFormat:@"Registration failed: %@", error], error);
                }
            
                return;
            }
        
            // Print device token to console
            NSLog(@"Pushy device token: %@", deviceToken);
        
            // Avoid resolving if did so in the past
            if (!resolved){
                resolved = YES;
            
                // Resolve promise with device token
                resolve(deviceToken);
            }
        }];
    });
}

RCT_EXPORT_METHOD(toggleIgnorePushPermissionDenial:(BOOL)toggle)
{
    // Enable/disable ignoring push permission denial
    [[self getPushyInstance] toggleIgnorePushPermissionDenial:toggle];
}

RCT_EXPORT_METHOD(toggleAPNs:(BOOL)value)
{
    // Toggle APNs for Local Push Connectivity support
    [[self getPushyInstance] toggleAPNs:value];
}

RCT_EXPORT_METHOD(toggleInAppBanner:(BOOL)toggle)
{
    // Run on main thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        // Enable/disable in-app notification banners (iOS 10+)
        [[self getPushyInstance] toggleInAppBanner:toggle];
        
        // Toggled off? (after previously being toggled on)
        if (!toggle) {
            // Reset UNUserNotificationCenterDelegate to nil to avoid displaying banner
            [UNUserNotificationCenter currentNotificationCenter].delegate = nil;
        }
    });
}


RCT_EXPORT_METHOD(toggleMethodSwizzling:(BOOL)toggle)
{
    // Enable/disable AppDelegate method swizzling
    [[self getPushyInstance] toggleMethodSwizzling:toggle];
}

RCT_EXPORT_METHOD(subscribe:(NSString *)topic resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    // Subscribe the device to topic
    [[self getPushyInstance] subscribeWithTopic:topic handler:^(NSError *error) {
        // Handle errors
        if (error != nil) {
            // Reject promise
            reject(@"Error", [NSString stringWithFormat:@"Subscribe failed: %@", error], error);
            return;
        }
        
        // Resolve promise
        resolve(@YES);
    }];
}

RCT_EXPORT_METHOD(unsubscribe:(NSString *)topic resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    // Unsubscribe the device from topic
    [[self getPushyInstance] unsubscribeWithTopic:topic handler:^(NSError *error) {
        // Handle errors
        if (error != nil) {
            // Reject promise
            reject(@"Error", [NSString stringWithFormat:@"Unsubscribe failed: %@", error], error);
            return;
        }
        
        // Resolve promise
        resolve(@YES);
    }];
}

RCT_EXPORT_METHOD(isRegistered:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    // Check if registered for push notifications
    BOOL isRegistered = [[self getPushyInstance] isRegistered];
    
    // Send result back to app
    resolve([NSNumber numberWithBool:isRegistered]);
}

RCT_EXPORT_METHOD(setProxyEndpoint:(NSString *)proxyEndpoint)
{
    // Empty endpoint?
    if ([proxyEndpoint length] == 0) {
        proxyEndpoint = nil;
    }
    
    // Set proxy endpoint
    [[self getPushyInstance] setProxyEndpointWithProxyEndpoint:proxyEndpoint];
}

RCT_EXPORT_METHOD(setEnterpriseConfig:(NSString *)apiEndpoint mqttEndpoint:(NSString *)mqttEndpoint)
{
    // Empty endpoint?
    if ([apiEndpoint length] == 0) {
        apiEndpoint = nil;
    }
    
    // Set Pushy Enterprise API endpoint
    [[self getPushyInstance] setEnterpriseConfigWithApiEndpoint:apiEndpoint];
}

RCT_EXPORT_METHOD(setAppId:(NSString *)appId)
{
    // Empty App ID?
    if ([appId length] == 0) {
        appId = nil;
    }
    
    // Set Pushy App ID
    [[self getPushyInstance] setAppId:appId];
}

RCT_EXPORT_METHOD(notify:(NSString *)title message:(NSString *)message payload:(id *)payload)
{
    // Run on main thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        // Display the notification as an alert
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:title
                                     message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        // Add an action button
        [alert addAction:[UIAlertAction
                          actionWithTitle:@"OK"
                          style:UIAlertActionStyleDefault
                          handler:nil]];
        
        // Show the alert dialog
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

RCT_EXPORT_METHOD(setBadge:(nonnull NSNumber *)badge)
{
    // Run on main thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        // Set app badge number
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[badge intValue]];
    });
}

- (NSArray<NSString *> *)supportedEvents
{
    // Emit Notification RTC Events
    return @[@"Notification", @"NotificationClick"];
}

@end

