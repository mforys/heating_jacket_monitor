//
//  ViewController.swift
//  HeatingJacketMonitor
//
//  Created by Marek Forys on 06/10/2021.
//

import UIKit
import CoreBluetooth

//let temperatureServiceCBUUID = CBUUID(string: "0x0000fe40cc7a482a984a7f2ed5b3e58f")
let temperatureServiceCBUUID = CBUUID(string:"0000FE40-CC7A-482A-984A-7F2ED5B3E58F")
let bmwMulServiceCBUUID = CBUUID(string:"11E0FED6-D13D-8F12-B6BF-D03CA4AD8662")
//characteristics
let heatingCharacteristicCBUUID = CBUUID(string:"0000FE41-8E22-4541-9D4C-21EDAE82ED19")
let temperatureCharacteristicCBUUID = CBUUID(string: "0000FE42-8E22-4541-9D4C-21EDAE82ED19")

var temperaturePeripheral: CBPeripheral!
var heatingCharacteristic: CBCharacteristic!

enum HeatingLevel {
    case None
    case Percent33
    case Percent66
    case Full
}

struct HeatingData {
  var heating: HeatingLevel
  var count: UInt8
}

struct TemperatureData {
  var temperature: Int16
  var operationTime: UInt32
  var count: UInt8
}

class ViewController: UIViewController
{
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var heatingLevelLabel: UILabel!
    @IBOutlet weak var heatingLevelSlider: UISlider!

    var centralManager: CBCentralManager!

    override func viewDidLoad()
    {
        super.viewDidLoad()

        centralManager = CBCentralManager(delegate: self, queue: nil)

        // Make the digits monospaces to avoid shifting when the numbers change
        temperatureLabel.font = UIFont.monospacedDigitSystemFont(ofSize: temperatureLabel.font!.pointSize,
                                                                 weight: .regular)

        onHeatingLevelReceived(HeatingLevel.None)
    }

    func onTemperatureReceived(_ temperature: Int)
    {
        temperatureLabel.text = String(temperature)
        print("Temperature displayed: \(temperature)")
    }
    
    @IBAction func onHeatingLevelSliderChanged(_ sender: Any)
    {
        guard (temperaturePeripheral != nil) else {
            heatingLevelSlider.value = 0
            return
        }

        switch (heatingLevelSlider.value)
        {
        case 0.0...20.0:
            //heatingLevelLabel.text = "None"
          updateHeatingLevel(heatingLevel: HeatingLevel.None)
        case 2.0...50.0:
            //heatingLevelLabel.text = "33%"
          updateHeatingLevel(heatingLevel: HeatingLevel.Percent33)
        case 50.0...75.0:
            //heatingLevelLabel.text = "66%"
          updateHeatingLevel(heatingLevel: HeatingLevel.Percent66)
        case 75.0...100.0:
            //heatingLevelLabel.text = "Full"
          updateHeatingLevel(heatingLevel: HeatingLevel.Full)
        default:
            print("Undefined level of heating set by Heating Level slider!")
        }
    }
    
    func updateHeatingLevel(heatingLevel: HeatingLevel)
    {
        guard (temperaturePeripheral != nil) else {
            return
        }

        var heatingLevelNumericValue = 0x00

        switch (heatingLevel)
        {
            case .None:
                heatingLevelNumericValue = 0x00
            case .Percent33:
                heatingLevelNumericValue = 0x01
            case .Percent66:
                heatingLevelNumericValue = 0x02
            case .Full:
                heatingLevelNumericValue = 0x03
        }

        var data = Data(count: 9)
        data[0] = UInt8(heatingLevelNumericValue)

        // Type withResponse cannot be used as it's not supported by Bluetooth device
        temperaturePeripheral.writeValue(data, for: heatingCharacteristic, type: .withoutResponse)
    }
    
    func onHeatingLevelReceived(_ heatingLevel: HeatingLevel)
    {
      switch (heatingLevel)
      {
        case HeatingLevel.None:
          heatingLevelLabel.text = "None"
            heatingLevelSlider.setValue(0.0, animated: false)
        case .Percent33:
          heatingLevelLabel.text = "33%"
            heatingLevelSlider.setValue(33, animated: false)
        case .Percent66:
          heatingLevelLabel.text = "66%"
            heatingLevelSlider.setValue(66, animated: false)
        case .Full:
          heatingLevelLabel.text = "Full"
          heatingLevelSlider.setValue(100, animated: false)
      }

      print("Heating level displayed: \(heatingLevel)")
    }
}

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
      print("Value: \(byte)")
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

//    for byte in byteArray {
//      print("Value: \(byte)")
//    }

    result.temperature = (Int16(byteArray[1]) << 8) + Int16(byteArray[0])
    result.operationTime = (UInt32(byteArray[5]) << 24) + (UInt32(byteArray[4]) << 16) + (UInt32(byteArray[3]) << 8) + UInt32(byteArray[2])
    result.count = UInt8(byteArray[6])
    return result
  }
}
