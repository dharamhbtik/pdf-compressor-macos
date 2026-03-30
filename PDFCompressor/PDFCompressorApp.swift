//
//  PDFCompressorApp.swift
//  PDFCompressor
//
//  Main app entry point
//

import SwiftUI

@main
struct PDFCompressorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, minHeight: 500)
        }
        .windowResizability(.contentSize)
    }
}
