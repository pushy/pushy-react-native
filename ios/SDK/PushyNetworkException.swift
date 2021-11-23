//
//  PushyNetworkException.swift
//  Pushy
//
//  Created by Pushy on 10/9/16.
//  Copyright © 2016 Pushy. All rights reserved.
//

import Foundation

enum PushyNetworkException: Error {
    case Error(String)
}

extension PushyNetworkException: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .Error(let reason): return reason
        }
    }
}
