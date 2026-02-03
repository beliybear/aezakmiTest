//
//  DatabaseService.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import Foundation
import CoreData

enum DeviceType: String {
    case bluetooth
    case lan
}

final class DatabaseService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    @discardableResult
    func createSession() -> ScanSession? {
        let session = ScanSession(context: context)
        session.id = UUID().uuidString
        session.date = Date()
        return session
    }

    func save() {
        guard context.hasChanges else { return }
        try? context.save()
    }

    @discardableResult
    func addBluetoothDevice(to session: ScanSession, name: String?, uuid: String, rssi: Int32, status: String?) -> Device? {
        let device = Device(context: context)
        device.id = UUID().uuidString
        device.deviceType = DeviceType.bluetooth.rawValue
        device.name = name
        device.uuid = uuid
        device.rssi = rssi
        device.status = status
        device.scanSession = session
        return device
    }

    @discardableResult
    func addLANDevice(to session: ScanSession, ipAddress: String, macAddress: String?, name: String?) -> Device? {
        let device = Device(context: context)
        device.id = UUID().uuidString
        device.deviceType = DeviceType.lan.rawValue
        device.ipAddress = ipAddress
        device.macAddress = macAddress
        device.name = name
        device.scanSession = session
        return device
    }

    func fetchSessions(from dateFrom: Date? = nil, to dateTo: Date? = nil) -> [ScanSession] {
        let request = ScanSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScanSession.date, ascending: false)]

        var predicates = [NSPredicate]()
        if let from = dateFrom {
            predicates.append(NSPredicate(format: "date >= %@", from as NSDate))
        }
        if let to = dateTo {
            predicates.append(NSPredicate(format: "date <= %@", to as NSDate))
        }
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        return (try? context.fetch(request)) ?? []
    }

    func fetchDevices(for session: ScanSession, nameContains: String? = nil) -> [Device] {
        let request = Device.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Device.name, ascending: true)]

        if let search = nameContains, !search.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "scanSession == %@", session),
                NSPredicate(format: "name CONTAINS[cd] %@ OR uuid CONTAINS[cd] %@ OR ipAddress CONTAINS[cd] %@", search, search, search)
            ])
        } else {
            request.predicate = NSPredicate(format: "scanSession == %@", session)
        }

        return (try? context.fetch(request)) ?? []
    }

    func fetchDevices(sessionId: String) -> [Device] {
        let request = Device.fetchRequest()
        request.predicate = NSPredicate(format: "scanSession.id == %@", sessionId)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Device.deviceType, ascending: true),
            NSSortDescriptor(keyPath: \Device.name, ascending: true)
        ]
        return (try? context.fetch(request)) ?? []
    }

    func fetchSession(byId id: String) -> ScanSession? {
        let request = ScanSession.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    func fetchDevice(byId id: String) -> Device? {
        let request = Device.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}
