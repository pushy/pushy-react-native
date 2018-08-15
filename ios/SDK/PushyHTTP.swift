//
//  PushyHTTP.swift
//  Pushy
//
//  Created by Pushy on 10/8/16.
//  Copyright © 2016 Pushy. All rights reserved.
//

import UIKit

public class PushyHTTP {
    static func postAsync(_ urlString : String, params : [String: Any], postCompleted: @escaping (Error?, [String:AnyObject]?) -> ()) {
        // Convert string to URL
        let url = URL(string: urlString)!
        
        // Create new request
        var request = URLRequest(url: url)
        
        // This is a POST request
        request.httpMethod = "POST"
        
        // Set request content type to JSON
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Serialize request JSON into string
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch let err {
            return postCompleted(err, nil)
        }
        
        // Execute request async
        let task = URLSession.shared.dataTask(with: request, completionHandler: {data, response, error in
            // Convert response to string (for debugging)
            // var test = String(data: data!, encoding: .utf8)
            
            // Got a protocol error?
            if error != nil {
                return postCompleted(PushyNetworkException.Error("Protocol error: \(error!)"), nil)
            }
            
            // Prepare response JSON dictionary
            var json: [String:AnyObject]
            
            do {
                // Serialize response JSON into string
                json = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:AnyObject]
            } catch let err {
                return postCompleted(err, nil)
            }
            
            // Got a JSON error?
            if json["error"] != nil {
                return postCompleted(PushyResponseException.Error(json["error"] as! String), nil)
            }
            
            // Return the JSON
            return postCompleted(nil, json)
        })
        
        // Execute the request
        task.resume()
    }
}
