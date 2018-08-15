//
//  PushyEnvironment.swift
//  Pushy
//
//  Created by Pushy on 10/11/16.
//  Copyright © 2016 Pushy. All rights reserved.
//

import Foundation

class PushyEnvironment : NSObject {
    static func getEnvironmentString() -> String {
        // Get embedded provision dictionary
        if let mobileProvision = getMobileProvision() {
            // Get entitlements dictionary
            let entitlements = mobileProvision.object(forKey: "Entitlements") as? NSDictionary
            // Check aps-environment variable for "development" as its value
            if let apsEnvironment = entitlements?["aps-environment"] as? NSString, apsEnvironment.isEqual(to: "development") {
                // This is indeed development
                return "development"
            }
        }
        
        // Default to production (safer this way)
        return "production"
    }

    static func getMobileProvision() -> NSDictionary? {
        // Prepare mobile provision
        var mobileProvision : NSDictionary? = nil
        
        // Build path to embedded provision in bundle
        let provisioningPath = Bundle.main.path(forResource:"embedded", ofType: "mobileprovision")
        
        // Can't find for some reason?
        if provisioningPath == nil {
            return nil
        }
        
        // NSISOLatin1 keeps the binary wrapper from being parsed as unicode and dropped as invalid
        let binaryString: NSString?
        
        do {
            // Read file using isoLatin1 encoding
            binaryString = try NSString(contentsOfFile: provisioningPath!, encoding: String.Encoding.isoLatin1.rawValue)
        } catch _ {
            return nil
        }
        
        // Scan the XML file from string
        let scanner = Scanner(string: binaryString! as String)
        
        // Scan up to the <plist
        var ok = scanner.scanUpTo("<plist", into: nil)
        
        // Failed?
        if !ok {
            return nil
        }
        
        // Prepare string of interesting properties
        var plistString : NSString? = ""
        
        // Scan up to the closing </plist> tag
        ok = scanner.scanUpTo("</plist>", into: &plistString)
        
        // Failed?
        if !ok {
            return nil
        }
        
        // Prepare a new string with opening and closing <plist> tags
        let newString = (plistString! as String) + "</plist>"
        
        // Convert latin1 string back to utf-8!
        if let plistdata_latin1 = newString.data(using: .isoLatin1) {
            do {
                // Actually parse the plist XML into a dictionary
                mobileProvision = try PropertyListSerialization.propertyList(from: plistdata_latin1, options: PropertyListSerialization.MutabilityOptions(), format: nil) as? NSDictionary
            }
            catch {
                return nil
            }
        }
        
        // If succeeded, return the provision
        return mobileProvision
    }
}
