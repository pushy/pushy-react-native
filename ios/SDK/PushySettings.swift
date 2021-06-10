//
//  PushySettings.swift
//  Pushy
//
//  Created by Pushy on 10/8/16.
//  Copyright © 2016 Pushy. All rights reserved.
//

import Foundation

public class PushySettings {
    static var pushyAppId = "_pushyAppId"
    static var pushyToken = "_pushyToken"
    static var apnsToken = "_pushyApnsToken"
    static var pushyTokenAuth = "_pushyTokenAuth"
    static var pushyEnterpriseApi = "_pushyEnterpriseApi"
    
    // Cross-reinstall key-value store
    static var keychain = Keychain()
    
    class func getString(_ key: String) -> String? {
        // Fetch value from Keychain
        let keychainValue = keychain[key]
        
        // Fetch value from UserDefaults
        let userDefaultsValue = UserDefaults.standard.string(forKey: key)
        
        // No value in either?
        if (keychainValue == nil && userDefaultsValue == nil) {
            return nil
        }
        
        // No Keychain value but UserDefaults has one?
        if (keychainValue == nil && userDefaultsValue != nil) {
            // Synchronize it to Keychain for improved persistence
            keychain[key] = userDefaultsValue
            
            // Return it
            return userDefaultsValue
        }
        
        // No UserDefaults value but Keychain has one?
        if (userDefaultsValue == nil && keychainValue != nil) {
            // Synchronize it to UserDefaults for improved persistence
            UserDefaults.standard.set(keychainValue, forKey: key)
            
            // Return it
            return keychainValue
        }
        
        // Value exists in both of them, return UserDefaults
        return userDefaultsValue
    }
    
    class func setString(_ key: String, _ value: String?) {
        // Store it in UserDefaults
        UserDefaults.standard.set(value, forKey: key)
        
        // Save it in Keychain for improved persistence
        keychain[key] = value
    }
}
