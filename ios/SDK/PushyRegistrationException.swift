//
//  PushyRegistrationException.swift
//  Pushy
//
//  Created by Pushy on 1/27/17.
//  Copyright © 2017 Pushy. All rights reserved.
//

import Foundation

enum PushyRegistrationException: Error {
    case Error(String, String)
}

extension PushyRegistrationException: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .Error(let reason, let code): return "\(reason) (\(code))"
        }
    }
}
