//
//  DeviceRow.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import Foundation
import CoreData

struct DeviceRow: Identifiable {
    let id: String
    let deviceType: DeviceType
    let title: String
    let subtitle: String
    let hasName: Bool

    static func from(_ device: Device) -> DeviceRow {
        let title: String
        let subtitle: String
        let hasName: Bool
        if device.deviceType == DeviceType.bluetooth.rawValue {
            let name = device.name ?? ""
            title = name.isEmpty ? (device.uuid ?? "—") : name
            subtitle = "RSSI: \(device.rssi) · \(device.status ?? "")"
            hasName = !name.isEmpty
        } else {
            let name = device.name ?? ""
            title = name.isEmpty ? (device.ipAddress ?? "—") : name
            subtitle = device.ipAddress ?? ""
            hasName = !name.isEmpty
        }
        return DeviceRow(
            id: device.id ?? UUID().uuidString,
            deviceType: DeviceType(rawValue: device.deviceType ?? "") ?? .lan,
            title: title,
            subtitle: subtitle,
            hasName: hasName
        )
    }

    static func sortedByDataRichness(_ rows: [DeviceRow]) -> [DeviceRow] {
        rows.sorted { r1, r2 in
            if r1.hasName != r2.hasName { return r1.hasName }
            return r1.title.localizedCaseInsensitiveCompare(r2.title) == .orderedAscending
        }
    }
}
