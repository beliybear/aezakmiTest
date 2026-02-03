//
//  ScanViewModel.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import Foundation
import Combine
import CoreBluetooth

enum ScanKind {
    case bluetooth
    case lan
}

final class ScanViewModel: ObservableObject {

    @Published var scanKind: ScanKind = .bluetooth
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published private(set) var devicesBT: [DeviceRow] = []
    @Published private(set) var devicesLAN: [DeviceRow] = []
    @Published var alertTitle: String = "Ошибка"

    private var progressTimer: Timer?
    private var scanStartTime: Date?
    private static let scanDuration: TimeInterval = 10

    var devices: [DeviceRow] {
        DeviceRow.sortedByDataRichness(scanKind == .bluetooth ? devicesBT : devicesLAN)
    }
    @Published var alertMessage: String?
    @Published var showAlert = false
    @Published var lastSessionId: String?

    private let services: ServicesHolder

    init(services: ServicesHolder) {
        self.services = services
        setupBluetooth()
        setupLAN()
    }

    private func setupBluetooth() {
        services.bt.onScanFinished = { [weak self] result in
            self?.handleBTResult(result)
        }
        services.bt.onStateChanged = { [weak self] state in
            if state != .poweredOn && state != .unknown {
                self?.isScanning = false
            }
        }
    }

    private func setupLAN() {
        services.lan.onScanFinished = { [weak self] result in
            self?.handleLANResult(result)
        }
    }

    func startScan() {
        guard !isScanning else { return }
        switch scanKind {
        case .bluetooth: devicesBT = []
        case .lan: devicesLAN = []
        }
        switch scanKind {
        case .bluetooth:
            isScanning = true
            scanProgress = 0
            scanStartTime = Date()
            startProgressTimer()
            services.bt.startScanning()
        case .lan:
            isScanning = true
            scanProgress = 0
            scanStartTime = Date()
            startProgressTimer()
            services.lan.startScanning()
        }
    }

    func stopScan() {
        stopProgressTimer()
        isScanning = false
        scanProgress = 0
        switch scanKind {
        case .bluetooth: services.bt.stopScanning()
        case .lan: services.lan.stopScanning()
        }
    }

    private func handleBTResult(_ result: BluetoothScanResult) {
        stopProgressTimer()
        isScanning = false
        scanProgress = 0
        switch result {
        case .success(let list):
            saveBTDevices(list)
            alertTitle = "Готово"
            alertMessage = "Сканирование завершено. Найдено устройств: \(list.count)"
            showAlert = true
        case .cancelled:
            break
        case .error(let err):
            alertTitle = "Ошибка"
            alertMessage = messageForBTError(err)
            showAlert = true
        }
    }

    private func handleLANResult(_ result: LANScanResult) {
        stopProgressTimer()
        isScanning = false
        scanProgress = 0
        switch result {
        case .success(let list):
            saveLANDevices(list)
            alertTitle = "Готово"
            alertMessage = "Сканирование завершено. Найдено устройств: \(list.count)"
            showAlert = true
        case .cancelled:
            break
        case .error(let err):
            alertTitle = "Ошибка"
            alertMessage = messageForLANError(err)
            showAlert = true
        }
    }

    private func saveBTDevices(_ list: [BluetoothDeviceItem]) {
        guard let session = services.db.createSession() else { return }
        for item in list {
            services.db.addBluetoothDevice(
                to: session,
                name: item.name,
                uuid: item.uuidString,
                rssi: Int32(item.rssi),
                status: item.status
            )
        }
        services.db.save()
        lastSessionId = session.id
        reloadDevices(sessionId: session.id ?? "", type: .bluetooth)
    }

    private func saveLANDevices(_ list: [LANDeviceItem]) {
        guard let session = services.db.createSession() else { return }
        for item in list {
            services.db.addLANDevice(
                to: session,
                ipAddress: item.ipAddress,
                macAddress: item.macAddress,
                name: item.name
            )
        }
        services.db.save()
        lastSessionId = session.id
        reloadDevices(sessionId: session.id ?? "", type: .lan)
    }

    private func reloadDevices(sessionId: String, type: DeviceType) {
        let list = services.db.fetchDevices(sessionId: sessionId).filter { DeviceType(rawValue: $0.deviceType ?? "") == type }
        let rows = list.map { DeviceRow.from($0) }
        switch type {
        case .bluetooth: devicesBT = rows
        case .lan: devicesLAN = rows
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, self.isScanning, let start = self.scanStartTime else {
                timer.invalidate()
                return
            }
            let elapsed = Date().timeIntervalSince(start)
            if elapsed >= Self.scanDuration {
                timer.invalidate()
                self.scanProgress = 1
                return
            }
            DispatchQueue.main.async {
                self.scanProgress = min(1, elapsed / Self.scanDuration)
            }
        }
        progressTimer?.tolerance = 0.02
        RunLoop.main.add(progressTimer!, forMode: .common)
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        scanStartTime = nil
    }

    private func messageForBTError(_ err: BluetoothError) -> String {
        switch err {
        case .poweredOff: return "Bluetooth выключен"
        case .unauthorized: return "Нет доступа к Bluetooth"
        case .unsupported: return "Bluetooth не поддерживается"
        case .unknown: return "Ошибка сканирования Bluetooth"
        }
    }

    private func messageForLANError(_ err: LANScanError) -> String {
        switch err {
        case .noWiFi: return "Нет подключения по Wi‑Fi"
        case .noLocalNetwork: return "Нет доступа к локальной сети"
        case .unknown: return "Ошибка сканирования сети"
        }
    }
}
