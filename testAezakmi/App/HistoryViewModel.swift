//
//  HistoryViewModel.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import Foundation
import Combine

struct SessionRow: Identifiable {
    let id: String
    let date: Date
    let deviceCount: Int
}

final class HistoryViewModel: ObservableObject {

    @Published var sessions: [SessionRow] = []
    @Published var dateFrom: Date?
    @Published var dateTo: Date?
    @Published var nameFilter: String = ""
    @Published var isFiltering = false

    private let services: ServicesHolder

    init(services: ServicesHolder) {
        self.services = services
    }

    func load() {
        let list = services.db.fetchSessions(from: dateFrom, to: dateTo)
        sessions = list.map { session in
            let devices = services.db.fetchDevices(sessionId: session.id ?? "")
            let count: Int
            if nameFilter.isEmpty {
                count = devices.count
            } else {
                count = services.db.fetchDevices(for: session, nameContains: nameFilter).count
            }
            return SessionRow(
                id: session.id ?? UUID().uuidString,
                date: session.date ?? Date(),
                deviceCount: count
            )
        }.filter { nameFilter.isEmpty || $0.deviceCount > 0 }
    }

    func devices(for sessionId: String) -> [DeviceRow] {
        guard let session = services.db.fetchSession(byId: sessionId) else { return [] }
        let list = services.db.fetchDevices(for: session, nameContains: nameFilter.isEmpty ? nil : nameFilter)
        return DeviceRow.sortedByDataRichness(list.map { DeviceRow.from($0) })
    }
}
