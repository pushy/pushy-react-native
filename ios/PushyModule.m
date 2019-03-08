#import "PushyModule.h"
#import "PushyRN-Swift.h"
#import <UserNotifications/UserNotifications.h>

@implementation PushyModule

RCT_EXPORT_MODULE();

Pushy *pushy;

- (Pushy *) getPushyInstance
{
    // Pushy instance singleton
    if (!pushy) {
        pushy = [[Pushy alloc]init:[UIApplication sharedApplication]];
    }
    
    return pushy;
}

RCT_EXPORT_METHOD(listen)
{
    // Handle push notifications
    [[self getPushyInstance] setNotificationHandler:^(NSDictionary *data, void (^completionHandler)(UIBackgroundFetchResult)) {
        // Print notification payload data
        NSLog(@"Received notification: %@", data);
        
        // Emit RCT event with notification payload dictionary
        [self sendEventWithName:@"Notification" body:data];
        
        // Call the completion handler immediately on behalf of the app
        completionHandler(UIBackgroundFetchResultNewData);
    }];
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

RCT_EXPORT_METHOD(setEnterpriseConfig:(NSString *)apiEndpoint)
{
    // Empty endpoint?
    if ([apiEndpoint length] == 0) {
        apiEndpoint = nil;
    }
    
    // Set Pushy Enterprise API endpoint
    [[self getPushyInstance] setEnterpriseConfigWithApiEndpoint:apiEndpoint];
}

RCT_EXPORT_METHOD(notify:(NSString *)title message:(NSString *)message)
{
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
        
        // Reset badge number
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    });
}

RCT_EXPORT_METHOD(setBadge:(nonnull NSNumber *)badge)
{
    // Set app badge number
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[badge intValue]];
}

- (NSArray<NSString *> *)supportedEvents
{
    // Emit Notification RTC Events
    return @[@"Notification"];
}

@end

