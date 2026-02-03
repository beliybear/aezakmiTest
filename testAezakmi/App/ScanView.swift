//
//  ScanView.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import SwiftUI

struct ScanView: View {

    @StateObject var viewModel: ScanViewModel
    @State private var emptyStatePulse: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Тип", selection: $viewModel.scanKind) {
                    Text("Bluetooth").tag(ScanKind.bluetooth)
                    Text("LAN").tag(ScanKind.lan)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .disabled(viewModel.isScanning)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if viewModel.isScanning {
                    scanOverlay
                } else if viewModel.devices.isEmpty {
                    emptyStateBeforeScan
                } else {
                    Text("Найдено: \(viewModel.devices.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)

                    List(viewModel.devices) { row in
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                scanButtonBar
            }
            .navigationTitle("Сканирование")
            .navigationBarTitleDisplayMode(.large)
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let msg = viewModel.alertMessage {
                    Text(msg)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var scanButtonBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: {
                if viewModel.isScanning {
                    viewModel.stopScan()
                } else {
                    viewModel.startScan()
                }
            }) {
                Text(viewModel.isScanning ? "Остановить" : "Сканировать")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var emptyStateBeforeScan: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .scaleEffect(emptyStatePulse ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: emptyStatePulse)

            VStack(spacing: 8) {
                Text("Устройства не найдены")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Нажмите «Сканировать» внизу экрана")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Image(systemName: "chevron.down")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.tertiary)
                .opacity(emptyStatePulse ? 0.6 : 0.3)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: emptyStatePulse)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { emptyStatePulse = true }
    }

    private var scanOverlay: some View {
        VStack(spacing: 24) {
            Text("Сканирование…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: viewModel.scanProgress, total: 1)
                .progressViewStyle(.linear)
                .tint(.accentColor)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.horizontal, 32)
                .animation(.linear(duration: 0.1), value: viewModel.scanProgress)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension ScanView {
    init(services: ServicesHolder) {
        _viewModel = StateObject(wrappedValue: ScanViewModel(services: services))
    }
}
