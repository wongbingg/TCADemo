//
//  TCADemoApp.swift
//  TCADemo
//
//  Created by 이원빈 on 2023/05/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCADemoApp: App {
    static let store = Store(initialState: CounterFeature.State()) {
        CounterFeature()
            ._printChanges() // MARK: action을 받을 때마다 상태를 print
    }
    var body: some Scene {
        WindowGroup {
            ContentView(store: TCADemoApp.store)
        }
    }
}
