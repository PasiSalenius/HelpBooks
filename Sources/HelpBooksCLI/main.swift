//
//  main.swift
//  HelpBooksCLI
//
//  Created by Pasi Salenius on 11.1.2026.
//

import Foundation

let cli = HelpBooksCLI()

Task {
    do {
        try await cli.run(arguments: CommandLine.arguments)
        exit(0)
    } catch {
        print("Error: \(error.localizedDescription)")
        exit(1)
    }
}

// Keep the process alive until the async task completes
RunLoop.main.run()

