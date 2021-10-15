//
//  ViewController+CBCentralManagerDelegate.swift
//  HeatingJacketMonitor
//
//  Created by Marek Forys on 06/10/2021.
//

import CoreBluetooth

//let temperatureServiceCBUUID = CBUUID(string:"0000FE40-CC7A-482A-984A-7F2ED5B3E58F")
//let bmwMulServiceCBUUID = CBUUID(string:"11E0FED6-D13D-8F12-B6BF-D03CA4AD8662")
//let iilat02CBUUID = CBUUID(string:"C841C029-B030-1BD5-1DE1-441BC5AFB476")
//let iilat02CBUUID2 = CBUUID(string:"EE310C37-01A2-EE93-88DE-6F60784BDF30")
let bmwMulname = "BMW_Mul"
let iilat02name = "iilat02"


extension ViewController: CBCentralManagerDelegate {

  func centralManagerDidUpdateState(_ central: CBCentralManager)
  {
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
        centralManager.scanForPeripherals(withServices: nil)
      @unknown default:
        assert(false, "Unknown state of CBCentralManager!")
    }
  }

  func centralManager(_ central: CBCentralManager,
                      didDiscover peripheral: CBPeripheral,
                      advertisementData: [String : Any],
                      rssi RSSI: NSNumber)
  {
    //if (peripheral.identifier.uuidString == bmwMulServiceCBUUID.uuidString)
    if (peripheral.name == iilat02name) || (peripheral.name == bmwMulname)
    {
      print("Correct BLE device found! \n\(peripheral)")
      temperaturePeripheral = peripheral
      temperaturePeripheral.delegate = self

      centralManager.stopScan()
      centralManager.connect(temperaturePeripheral)
    }
    else
    {
        print("Incorrect BLE device! \n\(peripheral)")
    }
  }

  func centralManager(_ central: CBCentralManager,
                      didConnect peripheral: CBPeripheral)
  {
    print("Peripheral \(peripheral) has been connected!")
    temperaturePeripheral.discoverServices(nil)
  }
}
