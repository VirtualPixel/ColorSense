//
//  Environment.swift
//  ColorSense
//
//  Created by Justin Wells on 4/10/25.
//

import Foundation

enum EnvironmentKeys {
    static let wishKitAPIKey = "WISHKIT_API_KEY"
}

struct EnvironmentValues {
    static func value(for key: String) -> String? {
        // Check process environment variables first (from .env)
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
            return value
        }

        // Then check Info.plist
        if let infoDictionary = Bundle.main.infoDictionary,
           let value = infoDictionary[key] as? String,
           !value.isEmpty {
            return value
        }

        // Check for .env file in configuration folder
        let paths = [
            Bundle.main.path(forResource: ".env", ofType: nil),
            Bundle.main.path(forResource: "configuration/.env", ofType: nil),
            Bundle.main.bundlePath + "/configuration/.env"
        ]

        for potentialPath in paths {
            if let path = potentialPath,
               let content = try? String(contentsOfFile: path, encoding: .utf8) {

                let lines = content.components(separatedBy: .newlines)

                for line in lines {
                    let components = line.components(separatedBy: "=")
                    if components.count >= 2 && components[0] == key {
                        let value = components[1]
                        return value
                    }
                }
            }
        }

        return nil
    }

    static var wishKitAPIKey: String {
        guard let apiKey = value(for: EnvironmentKeys.wishKitAPIKey) else {
            fatalError("\(EnvironmentKeys.wishKitAPIKey) not found")
        }
        return apiKey
    }
}
