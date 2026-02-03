//
//  LANScanService.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import Foundation

struct LANDeviceItem: Identifiable, Equatable {
    let id = UUID()
    let ipAddress: String
    let macAddress: String?
    let name: String?
}

enum LANScanResult {
    case success(devices: [LANDeviceItem])
    case cancelled
    case error(LANScanError)
}

enum LANScanError: Error {
    case noWiFi
    case noLocalNetwork
    case unknown(Error?)
}

private final class LockedBox<T> {
    private var value: T
    private let lock = NSLock()
    init(_ value: T) { self.value = value }
    func get() -> T { lock.withLock { value } }
    func set(_ value: T) { lock.withLock { self.value = value } }
}

final class LANScanService {

    static let scanDuration: TimeInterval = 10

    private var scanTask: Task<Void, Never>?
    private let isScanningBox = LockedBox(false)
    private let shouldStopScanBox = LockedBox(false)
    private let didFinishBox = LockedBox(false)

    private(set) var isScanning: Bool {
        get { isScanningBox.get() }
        set { isScanningBox.set(newValue) }
    }

    private var shouldStopScan: Bool {
        get { shouldStopScanBox.get() }
        set { shouldStopScanBox.set(newValue) }
    }

    var onScanFinished: ((LANScanResult) -> Void)?

    func startScanning() {
        guard !isScanning else { return }
        shouldStopScan = false
        didFinishBox.set(false)
        isScanning = true

        scanTask = Task { [weak self] in
            await self?.runScan()
        }
    }

    func stopScanning() {
        shouldStopScan = true
        scanTask?.cancel()
    }

    private func runScan() async {
        defer { isScanning = false }

        await withTaskCancellationHandler {
            await runScanBody()
        } onCancel: { [weak self] in
            Task { await self?.finish(.cancelled) }
        }
    }

    private func runScanBody() async {
        if !NetUtils.isReachableViaWiFi() {
            await finish(.error(.noWiFi))
            return
        }

        guard let localIp = NetUtils.localIp() as String?, !localIp.isEmpty,
              let netMask = NetUtils.netMask() as String?, !netMask.isEmpty else {
            await finish(.error(.noLocalNetwork))
            return
        }

        guard let ipRange = ipRangeForSubnet(localIp: localIp, netMask: netMask) else {
            await finish(.error(.noLocalNetwork))
            return
        }

        let liveIPs = await pingIPRange(ipRange, timeout: Self.scanDuration, shouldStopBox: shouldStopScanBox)

        if shouldStopScan || Task.isCancelled {
            await finish(.cancelled)
            return
        }

        let arpMap = parseARPTable()

        var devices = [LANDeviceItem]()
        for ip in liveIPs.sorted() {
            if shouldStopScan || Task.isCancelled {
                await finish(.cancelled)
                return
            }
            let mac = arpMap[ip]
            let name = NetUtils.ip2Host(ip) as String?
            devices.append(LANDeviceItem(ipAddress: ip, macAddress: mac, name: name))
        }

        for (ip, mac) in arpMap where !liveIPs.contains(ip) {
            if shouldStopScan || Task.isCancelled {
                await finish(.cancelled)
                return
            }
            if devices.contains(where: { $0.ipAddress == ip }) { continue }
            let name = NetUtils.ip2Host(ip) as String?
            devices.append(LANDeviceItem(ipAddress: ip, macAddress: mac, name: name))
        }

        devices.sort { d1, d2 in
            let hasName1 = !(d1.name?.isEmpty ?? true)
            let hasName2 = !(d2.name?.isEmpty ?? true)
            if hasName1 != hasName2 { return hasName1 }
            return d1.ipAddress.compare(d2.ipAddress, options: .numeric) == .orderedAscending
        }
        await finish(.success(devices: devices))
    }

    private func finish(_ result: LANScanResult) async {
        guard didFinishBox.get() == false else { return }
        didFinishBox.set(true)
        await MainActor.run { [weak self] in
            self?.onScanFinished?(result)
        }
    }

    private func ipRangeForSubnet(localIp: String, netMask: String) -> [String]? {
        let ipOctets = localIp.split(separator: ".").compactMap { Int($0) }
        let maskOctets = netMask.split(separator: ".").compactMap { Int($0) }
        guard ipOctets.count == 4, maskOctets.count == 4 else { return nil }

        var network = [0, 0, 0, 0]
        var broadcast = [0, 0, 0, 0]
        for i in 0..<4 {
            network[i] = ipOctets[i] & maskOctets[i]
            broadcast[i] = ipOctets[i] | (255 - maskOctets[i])
        }

        var result = [String]()
        var current = network
        while true {
            var carry = 1
            for i in (0..<4).reversed() {
                current[i] += carry
                carry = current[i] / 256
                current[i] %= 256
            }
            if carry > 0 { break }
            if current == broadcast { break }
            result.append(current.map { String($0) }.joined(separator: "."))
        }
        return result.isEmpty ? nil : result
    }

    private func pingIPRange(_ ips: [String], timeout: TimeInterval, shouldStopBox: LockedBox<Bool>) async -> Set<String> {
        let start = Date()
        let maxConcurrent = 30

        return await withTaskGroup(of: (String, Bool).self) { group in
            var live = Set<String>()
            var iterator = ips.makeIterator()
            var pending = 0

            func addNext() {
                if Date().timeIntervalSince(start) >= timeout || shouldStopBox.get() { return }
                guard let ip = iterator.next() else { return }
                pending += 1
                group.addTask {
                    let ok = await Task.detached(priority: .utility) { NetUtils.ping(ip) }.value
                    return (ip, ok)
                }
            }

            for _ in 0..<min(maxConcurrent, ips.count) {
                addNext()
            }

            for await (ip, ok) in group {
                if ok { live.insert(ip) }
                pending -= 1
                addNext()
            }

            return live
        }
    }

    private func parseARPTable() -> [String: String] {
        guard let arp = NetUtils.arpTable() as? [String] else { return [:] }
        var map = [String: String]()
        for line in arp {
            if !line.hasPrefix("ip=>") { continue }
            let rest = line.dropFirst(4)
            guard let spaceIdx = rest.firstIndex(of: " ") else { continue }
            let ip = String(rest[..<spaceIdx])
            let macPart = rest[rest.index(after: spaceIdx)...]
            if macPart.hasPrefix("mac: ") {
                let mac = String(macPart.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if !mac.isEmpty { map[ip] = mac }
            }
        }
        return map
    }
}
