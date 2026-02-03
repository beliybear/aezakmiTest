//
//  DeviceDetailView.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import SwiftUI
import CoreData

struct DeviceDetailView: View {

    let deviceId: String
    @EnvironmentObject var services: ServicesHolder

    private var device: Device? {
        services.db.fetchDevice(byId: deviceId)
    }

    var body: some View {
        Group {
            if let device = device {
                Form {
                    Section(header: Text(device.deviceType == DeviceType.bluetooth.rawValue ? "Bluetooth" : "LAN")) {
                        if device.deviceType == DeviceType.bluetooth.rawValue {
                            row("Имя", device.name)
                            row("UUID", device.uuid)
                            row("RSSI", "\(device.rssi)")
                            row("Статус", device.status)
                        } else {
                            row("Имя", device.name)
                            row("IP", device.ipAddress)
                            row("MAC", device.macAddress)
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Устройство не найдено")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(device?.name ?? device?.ipAddress ?? "Устройство")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String?) -> some View {
        if let value = value, !value.isEmpty {
            HStack {
                Text(label)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
