//
//  PushyPubSubException.swift
//  Pushy
//
//  Created by Pushy on 3/7/17.
//  Copyright © 2017 Pushy. All rights reserved.
//

import Foundation

enum PushyPubSubException: Error {
    case Error(String)
}

extension PushyPubSubException: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .Error(let reason): return reason
        }
    }
}
