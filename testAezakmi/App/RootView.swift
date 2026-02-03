//
//  RootView.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject var services: ServicesHolder

    var body: some View {
        TabView {
            ScanView(services: services)
                .tabItem {
                    Label("Сканирование", systemImage: "antenna.radiowaves.left.and.right")
                }
            HistoryView(services: services)
                .tabItem {
                    Label("История", systemImage: "clock.arrow.circlepath")
                }
        }
        .tint(.accentColor)
    }
}
