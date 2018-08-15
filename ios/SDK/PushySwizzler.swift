//
//  PushySwizzler.swift
//  Pushy
//
//  Created by Pushy on 10/7/16.
//  Copyright © 2016 Pushy. All rights reserved.
//

import UIKit

class PushySwizzler {
    class func swizzleMethodImplementations(_ className: AnyObject.Type, _ methodSelector: String) {
        // Build selector to original method
        let selector = Selector(methodSelector)
        
        // Grab original method
        let originalMethod = class_getInstanceMethod(className, selector)
        
        // Grab method to swap with (pushy_ + methodSelector)
        let swizzleMethod = class_getInstanceMethod(Pushy.self, selector)
        
        // Attempt to add our swizzled method to the class if it doesn't exist yet
        let didAddMethod = class_addMethod(className, selector, method_getImplementation(swizzleMethod!), method_getTypeEncoding(swizzleMethod!))
        
        // If we failed, method already defined
        if !didAddMethod {
            // Swizzle its implementation
            method_exchangeImplementations(originalMethod!, swizzleMethod!)
        }
    }
}
