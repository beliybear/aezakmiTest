//
//  BluetoothService.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import Foundation
import CoreBluetooth

struct BluetoothDeviceItem: Identifiable, Equatable {
    let id: UUID
    var name: String?
    var rssi: Int
    var status: String

    var uuidString: String { id.uuidString }
}

enum BluetoothScanResult {
    case success(devices: [BluetoothDeviceItem])
    case cancelled
    case error(BluetoothError)
}

enum BluetoothError: Error {
    case poweredOff
    case unauthorized
    case unsupported
    case unknown(Error?)
}

final class BluetoothService: NSObject {

    static let scanDuration: TimeInterval = 10

    private var centralManager: CBCentralManager?
    private var pendingScan = false
    private var discoveredPeripherals: [UUID: (peripheral: CBPeripheral, rssi: Int)] = [:]
    private var scanWorkItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: "testAezakmi.bluetooth")

    var state: CBManagerState { centralManager?.state ?? .unknown }

    private(set) var isScanning = false

    var onScanFinished: ((BluetoothScanResult) -> Void)?
    var onStateChanged: ((CBManagerState) -> Void)?

    var discoveredDevices: [BluetoothDeviceItem] {
        queue.sync {
            guard centralManager != nil else { return [] }
            return discoveredPeripherals.values.map { item in
                BluetoothDeviceItem(
                    id: item.peripheral.identifier,
                    name: item.peripheral.name,
                    rssi: item.rssi,
                    status: statusString(for: item.peripheral.state)
                )
            }
        }
    }

    private func ensureCentralManager() {
        guard centralManager == nil else { return }
        centralManager = CBCentralManager(delegate: self, queue: queue)
    }

    private func statusString(for state: CBPeripheralState) -> String {
        switch state {
        case .connected: return "Подключено"
        case .connecting: return "Подключение…"
        case .disconnecting: return "Отключение…"
        case .disconnected: return "Обнаружено"
        @unknown default: return "Обнаружено"
        }
    }

    override init() {
        super.init()
    }

    func startScanning() {
        queue.async { [weak self] in
            self?.startScanningOnQueue()
        }
    }

    private func startScanningOnQueue() {
        ensureCentralManager()
        guard let central = centralManager else { return }

        switch central.state {
        case .poweredOn:
            break
        case .unknown, .resetting:
            pendingScan = true
            return
        default:
            DispatchQueue.main.async { [weak self] in
                self?.onScanFinished?(.error(self?.errorForState() ?? .unsupported))
            }
            return
        }

        if isScanning { return }
        isScanning = true
        discoveredPeripherals.removeAll()

        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])

        scanWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.stopScanningOnQueue()
        }
        scanWorkItem = work
        queue.asyncAfter(deadline: .now() + Self.scanDuration, execute: work)
    }

    func stopScanning() {
        queue.async { [weak self] in
            self?.stopScanningOnQueue()
        }
    }

    private func stopScanningOnQueue() {
        scanWorkItem?.cancel()
        scanWorkItem = nil
        pendingScan = false
        guard isScanning else { return }
        isScanning = false
        centralManager?.stopScan()

        let devices = discoveredPeripherals.values.map { item in
            BluetoothDeviceItem(
                id: item.peripheral.identifier,
                name: item.peripheral.name,
                rssi: item.rssi,
                status: statusString(for: item.peripheral.state)
            )
        }

        DispatchQueue.main.async { [weak self] in
            self?.onScanFinished?(.success(devices: devices))
        }
    }

    private func errorForState() -> BluetoothError {
        switch centralManager?.state ?? .unknown {
        case .poweredOff: return .poweredOff
        case .unauthorized: return .unauthorized
        case .unsupported: return .unsupported
        default: return .unknown(nil)
        }
    }
}

extension BluetoothService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async { [weak self] in
            self?.onStateChanged?(central.state)
        }
        if pendingScan {
            switch central.state {
            case .poweredOn:
                pendingScan = false
                startScanningOnQueue()
            case .unknown, .resetting:
                break
            default:
                pendingScan = false
                DispatchQueue.main.async { [weak self] in
                    self?.onScanFinished?(.error(self?.errorForState() ?? .unsupported))
                }
            }
            return
        }
        if central.state != .poweredOn && isScanning {
            stopScanningOnQueue()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let rssiValue = RSSI.intValue
        if rssiValue != 127 {
            discoveredPeripherals[peripheral.identifier] = (peripheral, rssiValue)
        }
    }
}
