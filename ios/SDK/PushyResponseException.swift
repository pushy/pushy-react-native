//
//  PushyResponseException.swift
//  Pushy
//
//  Created by Pushy on 1/27/17.
//  Copyright © 2017 Pushy. All rights reserved.
//

import Foundation

enum PushyResponseException: Error {
    case Error(String)
}

extension PushyResponseException: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .Error(let reason): return reason
        }
    }
}
