//
//  ViewController.swift
//  HeatingJacketMonitor
//
//  Created by Marek Forys on 06/10/2021.
//

import UIKit
import CoreBluetooth

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

        disconnectFromDevice()

        // Make the digits monospaces to avoid shifting when the numbers change
        temperatureLabel.font = UIFont.monospacedDigitSystemFont(ofSize: temperatureLabel.font!.pointSize,
                                                                 weight: .regular)

        onHeatingLevelReceived(HeatingLevel.None)
    }

    override func viewDidDisappear(_ animated: Bool) {
        disconnectFromDevice()
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

    func disconnectFromDevice () {
        if temperaturePeripheral != nil {
            // We have a connection to the device
            // but we are not subscribed to the Transfer Characteristic for some reason.
            // Therefore, we will just disconnect from the peripheral
            centralManager?.cancelPeripheralConnection(temperaturePeripheral!)
        }
    }
}
