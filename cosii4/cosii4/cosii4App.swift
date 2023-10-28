//
//  cosii4App.swift
//  cosii4
//
//  Created by Alex on 18.10.23.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var cosii4App: Cosii4AppSwiftUI? // Свойство для хранения экземпляра

    
    func applicationWillTerminate(_ notification: Notification) {
        if let app = cosii4App {
            app.save()
        }
    }
}

@main
struct cosii4App: App {
    let app = Cosii4AppSwiftUI()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(app)
                .onAppear{
                    appDelegate.cosii4App = app
                }
        }
    }
}
