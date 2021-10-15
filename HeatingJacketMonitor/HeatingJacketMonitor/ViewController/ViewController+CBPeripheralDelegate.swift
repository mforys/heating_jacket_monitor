//
//  ViewController+CBPeripheralDelegate.swift
//  HeatingJacketMonitor
//
//  Created by Marek Forys on 07/10/2021.
//

import CoreBluetooth

//characteristics
let heatingCharacteristicCBUUID = CBUUID(string:"0000FE41-8E22-4541-9D4C-21EDAE82ED19")
let temperatureCharacteristicCBUUID = CBUUID(string: "0000FE42-8E22-4541-9D4C-21EDAE82ED19")

extension ViewController: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

    guard let services = peripheral.services else { return }

    print("Services of the connected device:")
    for service in services {
      print(service)
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                  error: Error?) {
    guard let characteristics = service.characteristics else { return }

    for characteristic in characteristics {
      print(characteristic)

        if characteristic.uuid == heatingCharacteristicCBUUID {
            heatingCharacteristic = characteristic
        }

      if characteristic.properties.contains(.read) {
        print("\(characteristic.uuid): properties contains .read")
        peripheral.readValue(for: characteristic)
      }
      if characteristic.properties.contains(.write) {
        print("\(characteristic.uuid): properties contains .write")
      }
      if characteristic.properties.contains(.writeWithoutResponse) {
        print("\(characteristic.uuid): properties contains .writeWithoutResponse")
      }
      if characteristic.properties.contains(.notify) {
        print("\(characteristic.uuid): properties contains .notify")
        // Subscribe to this characteristic,
        // so we can be notified when data comes from it
        peripheral.setNotifyValue(true, for: characteristic)
      }
    }
  }

  func peripheral(_ peripheral: CBPeripheral,
                      didUpdateNotificationStateFor characteristic: CBCharacteristic,
                      error: Error?) {
    // Perform any error handling if one occurred.
    // It's not necessary to abandon the connection from this kind of error
    if let error = error {
      print("Characteristic update notification error: \(error.localizedDescription)")
      return
    }

    // Ensure this characteristic is the one we configured
    guard characteristic.uuid == heatingCharacteristicCBUUID || characteristic.uuid == temperatureCharacteristicCBUUID else { return }

    // Check if it is successfully set as notifying
    if characteristic.isNotifying {
      print("Notifications for Characteristic: \(characteristic.uuid) have begun.")
    } else {
      print("Notifications for Characteristic: \(characteristic.uuid) have stopped. Disconnecting.")
      centralManager.cancelPeripheralConnection(peripheral)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                  error: Error?) {
    switch characteristic.uuid {
      case heatingCharacteristicCBUUID:
        if let heating = characteristic.value {
          print("Heating: \(heating)")
          let heatingData = heatingData(from: characteristic)
          print("Heating after calculation: \(heatingData.heating), count: \(heatingData.count)")
            onHeatingLevelReceived(heatingData.heating)
        } else {
          print("Heating: no value")
        }
      case temperatureCharacteristicCBUUID:
        if let temperatureVal = characteristic.value {
          print("Temperature: \(temperatureVal)")
          let temperatureData = temperatureData(from: characteristic)
          print("Temperature after calculation: \(temperatureData.temperature), operation time: \(temperatureData.operationTime), count: \(temperatureData.count)")
          onTemperatureReceived(Int(temperatureData.temperature))
        } else {
          print("Temperature: no value")
        }
      default:
        print("Unhandled Characteristic UUID: \(characteristic.uuid)")
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    guard let unwrappedError = error else {
      print("Value for characteristic \(characteristic) written OK!")
      return
    }

    print("Error \(unwrappedError) when writing a value for characteristic \(characteristic) !!!!")
  }

  func heatingData(from characteristic: CBCharacteristic) -> HeatingData {
    var result = HeatingData(heating: HeatingLevel.None, count: 0)
    guard let characteristicData = characteristic.value else { return result }
    let byteArray = [UInt8](characteristicData)

    for byte in byteArray {
      print("Heating value: \(byte)")
    }

    switch (byteArray[0])
    {
        case 0x00:
            result.heating = HeatingLevel.None
        case 0x01:
            result.heating = HeatingLevel.Percent33
        case 0x02:
            result.heating = HeatingLevel.Percent66
        case 0x03:
            result.heating = HeatingLevel.Full
        default:
            print("Undefined level of heating!!!")
            result.heating = HeatingLevel.None
    }
    result.count = UInt8(byteArray[1])
    return result
  }

  func temperatureData(from characteristic: CBCharacteristic) -> TemperatureData {
    var result = TemperatureData(temperature: 0, operationTime: 0, count: 0)
    guard let characteristicData = characteristic.value else { return result }
    let byteArray = [UInt8](characteristicData)

    result.temperature = (Int16(byteArray[1]) << 8) + Int16(byteArray[0])
    result.operationTime = (UInt32(byteArray[5]) << 24) + (UInt32(byteArray[4]) << 16) + (UInt32(byteArray[3]) << 8) + UInt32(byteArray[2])
    result.count = UInt8(byteArray[6])
    return result
  }
}

