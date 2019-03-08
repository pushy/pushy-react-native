//
//  Pushy.swift
//  Pushy
//
//  Created by Pushy on 10/7/16.
//  Copyright © 2016 Pushy. All rights reserved.
//

import UIKit
import UserNotifications

public class Pushy : NSObject {
    static var shared: Pushy?
    
    private var appDelegate: UIApplicationDelegate
    private var application: UIApplication
    private var registrationHandler: ((Error?, String) -> Void)?
    private var notificationHandler: (([AnyHashable : Any], @escaping ((UIBackgroundFetchResult) -> Void)) -> Void)?
    private var notificationOptions: Any?
    
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
        
        // Swizzle didReceiveRemoteNotification method
        PushySwizzler.swizzleMethodImplementations(self.appDelegate.superclass!, "application:didReceiveRemoteNotification:fetchCompletionHandler:")
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
        PushySwizzler.swizzleMethodImplementations(self.appDelegate.superclass!, "application:didRegisterForRemoteNotificationsWithDeviceToken:")
        PushySwizzler.swizzleMethodImplementations(self.appDelegate.superclass!, "application:didFailToRegisterForRemoteNotificationsWithError:")
        
        // Request an APNs token from Apple
        requestAPNsToken(self.application)
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
            
            // Register for notifications
            UNUserNotificationCenter.current().requestAuthorization(options:options){ (granted, error) in }
            application.registerForRemoteNotifications()
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
                // Failed to load APNs token from UserDefaults
                self.registrationHandler?(PushyRegistrationException.Error("Failed to load persisted APNs token."), "")
            }
        })
    }
    
    // Register a new Pushy device
    private func createNewDevice(_ apnsToken:String) {
        // Fetch app bundle ID
        let bundleID = Bundle.main.bundleIdentifier
        
        // Bundle ID fetch failed?
        guard let appBundleID = bundleID else {
            registrationHandler?(PushyRegistrationException.Error("Please configure a Bundle ID for your app to use Pushy."), "")
            return
        }
        
        // Determine if this is a sandbox or production APNs token
        let pushEnvironment = PushyEnvironment.getEnvironmentString()
        
        // Prepare /register API post data
        let params: [String:Any] = ["app": appBundleID, "platform": "ios", "pushToken": apnsToken, "pushEnvironment": pushEnvironment ]
        
        // Execute post request
        PushyHTTP.postAsync(self.getApiEndpoint() + "/register", params: params) { (err: Error?, response: [String:AnyObject]?) -> () in
            // JSON parse error?
            if err != nil {
                self.registrationHandler?(err, "")
                return
            }
            
            // Unwrap response json
            guard let json = response else {
                self.registrationHandler?(PushyRegistrationException.Error("An invalid response was encountered."), "")
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
        
        // Prepare request params
        let params: [String:Any] = ["token": pushyToken, "auth": pushyTokenAuth, "pushToken": apnsToken, "pushEnvironment": pushEnvironment]
        
        // Execute post request
        PushyHTTP.postAsync(self.getApiEndpoint() + "/devices/token", params: params) { (err: Error?, response: [String:AnyObject]?) -> () in
            // JSON parse error?
            if err != nil {
                self.registrationHandler?(err, "")
                return
            }
            
            // Unwrap json
            guard let json = response else {
                self.registrationHandler?(PushyRegistrationException.Error("An invalid response was encountered when updating the push token."), "")
                return
            }
            
            // Get success value
            let success = json["success"] as! Bool
            
            // Verify success
            if !success {
                self.registrationHandler?(PushyRegistrationException.Error("An unsuccessful response was encountered when updating the push token."), "")
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
            return resultHandler(PushyRegistrationException.Error("Failed to load the device credentials."), false)
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
                return resultHandler(PushyRegistrationException.Error("An invalid response was encountered when validating device credentials."), false)
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
            return handler(PushyRegistrationException.Error("Failed to load the device credentials."))
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
            return handler(PushyRegistrationException.Error("Failed to load the device credentials."))
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
    
    // Device registration check
    @objc public func isRegistered() -> Bool {
        // Attempt to fetch persisted Pushy token
        let token = PushySettings.getString(PushySettings.pushyToken)
        
        // Check for existance of non-nil token
        return token != nil;
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
    
    // Device received notification
    @objc public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Call the notification handler, if defined
        Pushy.shared?.notificationHandler?(userInfo, completionHandler)
    }
}

