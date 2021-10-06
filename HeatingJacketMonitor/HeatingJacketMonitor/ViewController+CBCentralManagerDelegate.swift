//
//  ViewController+CBCentralManagerDelegate.swift
//  HeatingJacketMonitor
//
//  Created by Marek Forys on 06/10/2021.
//

import CoreBluetooth

extension ViewController: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
      case .unknown:
        print("central.state is .unknown")
      case .resetting:
        print("central.state is .resetting")
      case .unsupported:
        print("central.state is .unsupported")
      case .unauthorized:
        print("central.state is .unauthorized")
      case .poweredOff:
        print("central.state is .poweredOff")
      case .poweredOn:
        print("central.state is .poweredOn")
        //centralManager.scanForPeripherals(withServices: [temperatureServiceCBUUID])
        //centralManager.scanForPeripherals(withServices: [bmwMulServiceCBUUID])
        centralManager.scanForPeripherals(withServices: nil)
      @unknown default:
        assert(false, "Unknown state of CBCentralManager!")
    }
  }

  func centralManager(_ central: CBCentralManager,
                      didDiscover peripheral: CBPeripheral,
                      advertisementData: [String : Any],
                      rssi RSSI: NSNumber) {
    print(peripheral)
    //print("identifier: \(peripheral.identifier), name: \(peripheral.name ?? "No name"), state: \(peripheral.state), services: \(peripheral.services)")
    if (peripheral.identifier.uuidString == bmwMulServiceCBUUID.uuidString)
    {
      temperaturePeripheral = peripheral
      temperaturePeripheral.delegate = self

      centralManager.stopScan()
      centralManager.connect(temperaturePeripheral)
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Peripheral \(peripheral) has been connected!")
    temperaturePeripheral.discoverServices(nil)
  }
}
