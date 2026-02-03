//
//  SessionDetailView.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import SwiftUI

struct SessionDetailView: View {

    let sessionId: String
    @ObservedObject var viewModel: HistoryViewModel

    private var devices: [DeviceRow] {
        viewModel.devices(for: sessionId)
    }

    var body: some View {
        Group {
            if devices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("Устройств не найдено")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(devices) { row in
                    NavigationLink(destination: DeviceDetailView(deviceId: row.id).id(row.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .font(.headline)
                            Text(row.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .id(row.id)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Устройства")
        .navigationBarTitleDisplayMode(.inline)
    }
}
