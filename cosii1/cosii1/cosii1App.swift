//
//  cosii1App.swift
//  cosii1
//
//  Created by Alex on 27.09.23.
//

import SwiftUI

@main
struct cosii1App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Cosii1AppSwiftUI())
        }
    }
}
