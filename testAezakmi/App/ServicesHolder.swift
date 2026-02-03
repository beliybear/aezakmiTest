//
//  ServicesHolder.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import Foundation
import CoreData
import Combine

final class ServicesHolder: ObservableObject {

    let db: DatabaseService
    let bt: BluetoothService
    let lan: LANScanService

    init(context: NSManagedObjectContext) {
        self.db = DatabaseService(context: context)
        self.bt = BluetoothService()
        self.lan = LANScanService()
    }
}
