//
//  Pushy.swift
//  Pushy
//
//  Created by Pushy on 10/7/16.
//  Copyright © 2016 Pushy. All rights reserved.
//

import UIKit
import UserNotifications

public class Pushy : NSObject, UNUserNotificationCenterDelegate {
    public static var shared: Pushy?
    
    private var appDelegate: UIApplicationDelegate
    private var application: UIApplication
    private var registrationHandler: ((Error?, String) -> Void)?
    private var notificationHandler: (([AnyHashable : Any], @escaping ((UIBackgroundFetchResult) -> Void)) -> Void)?
    private var notificationClickListener: (([AnyHashable : Any]) -> Void)?
    private var notificationOptions: Any?
    private var ignorePushPermissionDenial: Bool = false
    
    @objc public init(_ application: UIApplication) {
        // Store application and app delegate for later
        self.application = application
        self.appDelegate = application.delegate!
        
        // Initialize Pushy instance before accessing the self object
        super.init()
        
        // Store Pushy instance for later, but don't overwrite an existing instance if already initialized
        if Pushy.shared == nil {
            Pushy.shared = self
        }
    }
    
    // Define a notification handler to invoke when device receives a notification
    @objc public func setNotificationHandler(_ notificationHandler: @escaping ([AnyHashable : Any], @escaping ((UIBackgroundFetchResult) -> Void)) -> Void) {
        // Save the handler for later
        self.notificationHandler = notificationHandler
        
        // Swizzle didReceiveRemoteNotification methods
        PushySwizzler.swizzleMethodImplementations(type(of: self.appDelegate), "application:didReceiveRemoteNotification:")
        PushySwizzler.swizzleMethodImplementations(type(of: self.appDelegate), "application:didReceiveRemoteNotification:fetchCompletionHandler:")
        
        // In-app notification banner support (iOS 10+, defaults to off)
        // Set delegate to hook into userNotificationCenter callbacks
        if #available(iOS 10.0, *), PushySettings.getBoolean(PushySettings.pushyInAppBanner, false), PushySettings.getBoolean(PushySettings.pushyMethodSwizzling, true) {
            UNUserNotificationCenter.current().delegate = self
        }
    }
    
    // Define a notification click handler to invoke when user taps a notification
    @objc public func setNotificationClickListener(_ notificationClickListener: @escaping ([AnyHashable : Any]) -> Void) {
        // Save the listener for later
        self.notificationClickListener = notificationClickListener
    }
    
    // Display in-app notification banners (iOS 10+) and invoke notification handler
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Call the notification handler, if defined
        Pushy.shared?.notificationHandler?(notification.request.content.userInfo, {(UIBackgroundFetchResult) in})
        
        // Show in-app banner (no sound or badge)
        completionHandler([.alert])
    }
    
    // Notification click on in-app banner (iOS 10+), invoke notification click listener
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Call the notification click listener, if defined
        Pushy.shared?.notificationClickListener?(response.notification.request.content.userInfo)
        
        // Finished processing notification
        completionHandler()
    }
    
    // Make it possible to pass in custom iOS 10+ notification options ([.badge, .sound, .alert, ...])
    @available(iOS 10.0, *)
    @objc public func setCustomNotificationOptions(_ options:UNAuthorizationOptions) {
        // Save the options for later
        self.notificationOptions = options
    }
    
    // Register for push notifications (called from AppDelegate.didFinishLaunchingWithOptions)
    @objc public func register(_ registrationHandler: @escaping (Error?, String) -> Void) {
        // Save the handler for later
        self.registrationHandler = registrationHandler
        
        // Swizzle methods (will call method with same selector in Pushy class)
        PushySwizzler.swizzleMethodImplementations(type(of: self.appDelegate), "application:didRegisterForRemoteNotificationsWithDeviceToken:")
        PushySwizzler.swizzleMethodImplementations(type(of: self.appDelegate), "application:didFailToRegisterForRemoteNotificationsWithError:")
        
        // Run on main thread (access to UIApplication.shared.currentUserNotificationSettings)
        DispatchQueue.main.async {
            // Check if the user previously denied the push request dialog (and Pushy is registered)
            if PushySettings.getString(PushySettings.pushyToken, userDefaultsOnly: true) != nil && UIApplication.shared.currentUserNotificationSettings?.types == [] && !self.ignorePushPermissionDenial {
                Pushy.shared?.registrationHandler?(PushyRegistrationException.Error("Please enable push notifications for this app in the iOS settings.", "PUSH_PERMISSION_DENIED"), "")
                return
            }
        
            // Request an APNs token from Apple
            self.requestAPNsToken(self.application)
        }
    }
    
    // Backwards-compatible method for requesting an APNs token from Apple
    private func requestAPNsToken(_ application: UIApplication) {
        // iOS 10+ support
        if #available(iOS 10, *) {
            // Default iOS 10+ options
            var options: UNAuthorizationOptions = [UNAuthorizationOptions.badge, UNAuthorizationOptions.alert, UNAuthorizationOptions.sound]
            
            // Custom options passed in?
            if let customOptions = notificationOptions {
                options = customOptions as! UNAuthorizationOptions
            }
            
            // Request authorization (show push dialog)
            UNUserNotificationCenter.current().requestAuthorization(options:options){ (granted, error) in
                // Show error if user didn't grant permission
                if !granted && !self.ignorePushPermissionDenial { Pushy.shared?.registrationHandler?(PushyRegistrationException.Error("Please enable push notifications for this app in the iOS settings.", "PUSH_PERMISSION_DENIED"), "")
                    return
                }
                
                // Back to main thread, register with APNs
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
            // iOS 9 support
        else if #available(iOS 9, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 8 support
        else if #available(iOS 8, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 7 support
        else {
            application.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
        }
    }
    
    // Called automatically when APNs has assigned the device a unique token
    @objc public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)}).lowercased()
        
        // Pass it back to the Pushy instance for conversion
        Pushy.shared?.registerPushyDevice(apnsToken: deviceTokenString)
    }
    
    // Converts an APNs token to Pushy device token
    private func registerPushyDevice(apnsToken: String) {
        // Attempt to fetch persisted Pushy token
        let token = PushySettings.getString(PushySettings.pushyToken)
        
        // First time?
        if token == nil {
            // Create a new Pushy device
            return createNewDevice(apnsToken)
        }
        
        // Validate existing device credentials
        validateCredentials({ (error, credentialsValid) in
            // Handle validation errors
            if error != nil {
                self.registrationHandler?(error, "")
                return
            }
            
            // Are credentials invalid?
            if !credentialsValid {
                // Create a new device using the token
                return self.createNewDevice(apnsToken)
            }
            
            // Get previously-stored APNs token
            if let previousApnsToken = PushySettings.getString(PushySettings.apnsToken) {
                // Token changed?
                if (apnsToken != previousApnsToken) {
                    // Update APNs token server-side
                    return self.updateApnsToken(apnsToken)
                }
                
                // APNs token didn't change
                self.registrationHandler?(nil, token!)
            }
            else {
                // Failed to load previously-stored APNs token,
                // ensure Pushy backend has the most up-to-date token
                return self.updateApnsToken(apnsToken)
            }
        })
    }
    
    // Register a new Pushy device
    private func createNewDevice(_ apnsToken:String) {
        // Fetch app bundle ID
        let bundleId = Bundle.main.bundleIdentifier
        
        // Bundle ID fetch failed?
        guard let appBundleId = bundleId else {
            registrationHandler?(PushyRegistrationException.Error("Please configure a Bundle ID for your app to use Pushy.", "MISSING_BUNDLE_ID"), "")
            return
        }
        
        // Fetch custom Pushy App ID (may be null)
        let appId = PushySettings.getString(PushySettings.pushyAppId)
        
        // Determine if this is a sandbox or production APNs token
        let pushEnvironment = PushyEnvironment.getEnvironmentString()
        
        // Prepare /register API post data
        var params: [String:Any] = ["platform": "ios", "pushToken": apnsToken, "pushEnvironment": pushEnvironment, "pushBundle": appBundleId ]
        
        // Authenticate using Bundle ID by default
        if appId == nil {
            params["app"] = appBundleId
        }
        else {
            // Authenticate using provided Pushy App ID
            params["appId"] = appId!
        }
        
        // Execute post request
        PushyHTTP.postAsync(self.getApiEndpoint() + "/register", params: params) { (err: Error?, response: [String:AnyObject]?) -> () in
            // JSON parse error?
            if err != nil {
                self.registrationHandler?(err, "")
                return
            }
            
            // Unwrap response json
            guard let json = response else {
                self.registrationHandler?(PushyRegistrationException.Error("An invalid response was encountered.", "INVALID_JSON_RESPONSE"), "")
                return
            }
            
            // If we are here, registration succeeded
            let deviceToken = json["token"] as! String
            let deviceAuth = json["auth"] as! String
            
            // Store device token and auth in UserDefaults
            PushySettings.setString(PushySettings.apnsToken, apnsToken)
            PushySettings.setString(PushySettings.pushyToken, deviceToken)
            PushySettings.setString(PushySettings.pushyTokenAuth, deviceAuth)
            
            // All done
            self.registrationHandler?(nil, deviceToken)
        }
    }
    
    // Update remote APNs token
    private func updateApnsToken(_ apnsToken: String) {
        // Load device token & auth
        guard let pushyToken = PushySettings.getString(PushySettings.pushyToken), let pushyTokenAuth = PushySettings.getString(PushySettings.pushyTokenAuth) else {
            return
        }
        
        // Determine if this is a sandbox or production APNs token
        let pushEnvironment = PushyEnvironment.getEnvironmentString()
        
        // Fetch app bundle ID
        let bundleId = Bundle.main.bundleIdentifier
        
        // Bundle ID fetch failed?
        guard let appBundleId = bundleId else {
            self.registrationHandler?(PushyRegistrationException.Error("Please configure a Bundle ID for your app to use Pushy.", "MISSING_BUNDLE_ID"), "")
            return
        }
        
        // Prepare request params
        let params: [String:Any] = ["token": pushyToken, "auth": pushyTokenAuth, "pushToken": apnsToken, "pushEnvironment": pushEnvironment, "pushBundle": appBundleId]
        
        // Execute post request
        PushyHTTP.postAsync(self.getApiEndpoint() + "/devices/token", params: params) { (err: Error?, response: [String:AnyObject]?) -> () in
            // JSON parse error?
            if err != nil {
                self.registrationHandler?(err, "")
                return
            }
            
            // Unwrap json
            guard let json = response else {
                self.registrationHandler?(PushyRegistrationException.Error("An invalid response was encountered when updating the push token.", "INVALID_JSON_RESPONSE"), "")
                return
            }
            
            // Get success value
            let success = json["success"] as! Bool
            
            // Verify success
            if !success {
                self.registrationHandler?(PushyRegistrationException.Error("An unsuccessful response was encountered when updating the push token.", "UNSUCCESSFUL_RESPONSE"), "")
                return
            }
            
            // Store new APNS token to avoid re-updating it
            PushySettings.setString(PushySettings.apnsToken, apnsToken)
            
            // Done updating APNS token
            self.registrationHandler?(nil, pushyToken)
        }
    }
    
    // Validate device token and auth key
    private func validateCredentials(_ resultHandler: @escaping (Error?, Bool) -> Void) {
        // Load device token & auth
        guard let pushyToken = PushySettings.getString(PushySettings.pushyToken), let pushyTokenAuth = PushySettings.getString(PushySettings.pushyTokenAuth) else {
            return resultHandler(PushyRegistrationException.Error("Failed to load the device credentials.", "DEVICE_CREDENTIALS_ERROR"), false)
        }
        
        // Prepare request params
        let params: [String:Any] = ["token": pushyToken, "auth": pushyTokenAuth]
        
        // Execute post request
        PushyHTTP.postAsync(self.getApiEndpoint() + "/devices/auth", params: params) { (err: Error?, response: [String:AnyObject]?) -> () in
            // JSON parse error?
            if err != nil {
                // Did we get json["error"] response exception?
                if err is PushyResponseException {
                    // Auth is invalid
                    return resultHandler(nil, false)
                }
                
                // Throw network error and stop execution
                return resultHandler(err, false)
            }
            
            // Unwrap json
            guard let json = response else {
                return resultHandler(PushyRegistrationException.Error("An invalid response was encountered when validating device credentials.", "INVALID_JSON_RESPONSE"), false)
            }
            
            // Get success value
            let success = json["success"] as! Bool
            
            // Verify credentials validity
            if !success {
                return resultHandler(nil, false)
            }
            
            // Credentials are valid!
            resultHandler(nil, true)
        }
    }
    
    // Subscribe to single topic
    @objc public func subscribe(topic: String, handler: @escaping (Error?) -> Void) {
        // Call multi-topic subscribe function
        subscribe(topics: [topic], handler: handler)
    }
    
    // Subscribe to multiple topics
    @objc public func subscribe(topics: [String], handler: @escaping (Error?) -> Void) {
        // Load device token & auth
        guard let pushyToken = PushySettings.getString(PushySettings.pushyToken), let pushyTokenAuth = PushySettings.getString(PushySettings.pushyTokenAuth) else {
            return handler(PushyRegistrationException.Error("Failed to load the device credentials.", "DEVICE_CREDENTIALS_ERROR"))
        }
        
        // Prepare request params
        let params: [String:Any] = ["token": pushyToken, "auth": pushyTokenAuth, "topics": topics]
        
        // Execute post request
        PushyHTTP.postAsync(self.getApiEndpoint() + "/devices/subscribe", params: params) { (err: Error?, response: [String:AnyObject]?) -> () in
            // JSON parse error?
            if err != nil {
                // Throw network error and stop execution
                return handler(err)
            }
            
            // Unwrap json
            guard let json = response else {
                return handler(PushyPubSubException.Error("An invalid response was encountered when subscribing the device to topic(s)."))
            }
            
            // Get success value
            let success = json["success"] as! Bool
            
            // Verify subscribe success
            if !success {
                return handler(PushyPubSubException.Error("An invalid response was encountered."))
            }
            
            // Subscribe success
            handler(nil)
        }
    }
    
    
    // Unsubscribe from single topic
    @objc public func unsubscribe(topic: String, handler: @escaping (Error?) -> Void) {
        // Call multi-topic unsubscribe function
        unsubscribe(topics: [topic], handler: handler)
    }
    
    // Unsubscribe from multiple topics
    @objc public func unsubscribe(topics: [String], handler: @escaping (Error?) -> Void) {
        // Load device token & auth
        guard let pushyToken = PushySettings.getString(PushySettings.pushyToken), let pushyTokenAuth = PushySettings.getString(PushySettings.pushyTokenAuth) else {
            return handler(PushyRegistrationException.Error("Failed to load the device credentials.", "DEVICE_CREDENTIALS_ERROR"))
        }
        
        // Prepare request params
        let params: [String:Any] = ["token": pushyToken, "auth": pushyTokenAuth, "topics": topics]
        
        // Execute post request
        PushyHTTP.postAsync(self.getApiEndpoint() + "/devices/unsubscribe", params: params) { (err: Error?, response: [String:AnyObject]?) -> () in
            // JSON parse error?
            if err != nil {
                // Throw network error and stop execution
                return handler(err)
            }
            
            // Unwrap json
            guard let json = response else {
                return handler(PushyPubSubException.Error("An invalid response was encountered when unsubscribing the device to topic(s)."))
            }
            
            // Get success value
            let success = json["success"] as! Bool
            
            // Verify unsubscribe success
            if !success {
                return handler(PushyPubSubException.Error("An invalid response was encountered."))
            }
            
            // Unsubscribe success
            handler(nil)
        }
    }
    
    // Support for Pushy Enterprise
    @objc public func setEnterpriseConfig(apiEndpoint: String?) {
        // If nil, clear persisted Pushy Enterprise API endpoint
        if (apiEndpoint == nil) {
            return PushySettings.setString(PushySettings.pushyEnterpriseApi, nil)
        }
        
        // Mutable variable
        var endpoint = apiEndpoint!
        
        // Strip trailing slash
        if endpoint.hasSuffix("/") {
            endpoint = String(endpoint.prefix(endpoint.count - 1))
        }
        
        // Fetch previous enterprise endpoint
        let previousEndpoint = PushySettings.getString(PushySettings.pushyEnterpriseApi)
        
        // Check if this is a new API endpoint URL
        if endpoint != previousEndpoint {
            // Unregister device
            PushySettings.setString(PushySettings.apnsToken, nil)
            PushySettings.setString(PushySettings.pushyToken, nil)
            PushySettings.setString(PushySettings.pushyTokenAuth, nil)
        }
        
        // Persist enterprise API endpoint
        PushySettings.setString(PushySettings.pushyEnterpriseApi, endpoint)
    }
    
    // Support for Pushy App ID authentication instead of Bundle ID-based auth
    @objc public func setAppId(_ appId: String?) {
        // Fetch previous App ID
        let previousAppId = PushySettings.getString(PushySettings.pushyAppId)
        
        // Check if this is a new Pushy App ID
        if appId != previousAppId {
            // Unregister device
            PushySettings.setString(PushySettings.apnsToken, nil)
            PushySettings.setString(PushySettings.pushyToken, nil)
            PushySettings.setString(PushySettings.pushyTokenAuth, nil)
        }
        
        // Update stored value
        if (appId != nil) {
            PushySettings.setString(PushySettings.pushyAppId, appId!)
        }
        else {
            PushySettings.setString(PushySettings.pushyAppId, nil)
        }
    }
    
    // Support for silent/foreground notifications without push permission consent (defaults to off)
    @objc public func toggleIgnorePushPermissionDenial(_ value: Bool) {
        self.ignorePushPermissionDenial = value;
    }
    
    // Support for toggling in-app notification banner (defaults to off)
    @objc public func toggleInAppBanner(_ value: Bool) {
        PushySettings.setBoolean(PushySettings.pushyInAppBanner, value)
    }
    
    // Support for toggling AppDelegate method swizzling (defaults to on)
    @objc public func toggleMethodSwizzling(_ value: Bool) {
        PushySettings.setBoolean(PushySettings.pushyMethodSwizzling, value)
    }
    
    // Device registration check
    @objc public func isRegistered() -> Bool {
        // Check if APNs is registered
        if !UIApplication.shared.isRegisteredForRemoteNotifications {
            return false
        }
        
        // Check if user turned off iOS notifications or denied push dialog
        if UIApplication.shared.currentUserNotificationSettings?.types == [] {
            return false
        }
        
        // Check if Pushy device token is assigned to current app instance
        if (PushySettings.getString(PushySettings.pushyToken, userDefaultsOnly: true) == nil) {
            return false
        }
        
        // Fallback to true
        return true
    }
    
    // API endpoint getter function
    @objc public func getApiEndpoint() -> String {
        // Check for a configured enterprise API endpoint
        let enterpriseApiEndpoint = PushySettings.getString(PushySettings.pushyEnterpriseApi)
        
        // Default to public Pushy API if missing
        if enterpriseApiEndpoint == nil {
            return PushyConfig.apiBaseUrl
        }
        
        // Return enterprise endpoint
        return enterpriseApiEndpoint!
    }
    
    // APNs failed to register the device for push notifications
    @objc public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Call the registration handler, if defined (pass empty string as token)
        Pushy.shared?.registrationHandler?(error, "")
    }
    
    // Device received notification (legacy callback)
    @objc public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        // App opened from notification and click listener defined?
        if (application.applicationState == UIApplication.State.inactive && Pushy.shared?.notificationClickListener != nil) {
            // Call the notification click listener
            Pushy.shared?.notificationClickListener?(userInfo)
        } else {
            // Call the incoming notification handler
            Pushy.shared?.notificationHandler?(userInfo, {(UIBackgroundFetchResult) in})
        }
    }
    
    // Device received notification (new callback with completionHandler)
    @objc public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // App opened from notification and click listener defined?
        if (application.applicationState == UIApplication.State.inactive && Pushy.shared?.notificationClickListener != nil) {
            // Call the notification click listener
            Pushy.shared?.notificationClickListener?(userInfo)
            
            // Done processing notification
            completionHandler(UIBackgroundFetchResult.newData)
        } else {
            // Call the incoming notification handler
            Pushy.shared?.notificationHandler?(userInfo, completionHandler)
        }
    }
}

