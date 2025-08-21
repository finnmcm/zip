//
//  ZipApp.swift
//  Zip
//
//  Created by Finn McMillan on 8/19/25.
//

import SwiftUI
import Inject

@main
struct ZipApp: App {
    init() {
        #if DEBUG
        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        #endif
    }
    @ObserveInjection var inject
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .enableInjection()  // Just once here
        }
    }
}
