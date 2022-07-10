//
//  Copyright © 2022 Ohlulu. All rights reserved.
//

import Combine
import CoreBluetooth
import Foundation

public class BLEClient: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    public enum Error: Swift.Error {
        case centralStateError
        case noBatteryNoService
        case noBatteryCharacteristic
        case noBatteryData
    }
    
    private let batterySubject = CurrentValueSubject<BatteryState, Never>(.notConnect)
    public var batteryPublisher: AnyPublisher<BatteryState, Never> {
        return batterySubject.eraseToAnyPublisher()
    }
    
    private lazy var centralManager = CBCentralManager(delegate: self, queue: nil)
    private var peripheral: CBPeripheral?
    
    
    override init() {
        super.init()
        start()
    }
    
    private func start() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEClient {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            return batterySubject.send(.failure(Error.centralStateError))
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let peripheralName = peripheral.name, !peripheralName.isEmpty else { return }
        central.stopScan()
        central.connect(peripheral, options: nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        peripheral.discoverServices(nil)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard let error = error else { return }
        batterySubject.send(.failure(error))
    }
}

// MARK: - CBPeripheralDelegate

extension BLEClient {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            return batterySubject.send(.failure(error))
        }

        guard
            let services = peripheral.services,
            let batteryService = services.first(where: { $0.uuid == CBUUID.Service.battery })
        else {
            return batterySubject.send(.failure(Error.noBatteryNoService))
        }
        
        peripheral.discoverCharacteristics(nil, for: batteryService)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            return batterySubject.send(.failure(error))
        }
        
        guard
            let characteristics = service.characteristics,
            let batteryCharacteristic = characteristics.first(where: { $0.uuid == CBUUID.Characteristic.battery })
        else {
            return batterySubject.send(.failure(Error.noBatteryCharacteristic))
        }
        
        peripheral.readValue(for: batteryCharacteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == CBUUID.Characteristic.battery else { return }
        guard
            let data = characteristic.value,
            let batteryLevel = data.first
        else {
            return batterySubject.send(.failure(Error.noBatteryData))
        }
        
        batterySubject.send(.level(Int(batteryLevel)))
    }
}
