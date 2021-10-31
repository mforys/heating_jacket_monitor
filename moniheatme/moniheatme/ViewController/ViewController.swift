//
//  ViewController.swift
//  moniheatme
//
//  Created by Marek Forys on 06/10/2021.
//

import UIKit
import CoreBluetooth

var temperaturePeripheral: CBPeripheral!
var heatingCharacteristic: CBCharacteristic!
var receivedHeatingLevel = HeatingLevel.None
var sliderUpdateCount = 0

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
    //@IBOutlet weak var syncButton: UIButton!

    var centralManager: CBCentralManager!
    var httpController: HttpController!

    var currentTemperature:Int = 0

    override func viewDidLoad()
    {
        super.viewDidLoad()

        centralManager = CBCentralManager(delegate: self, queue: nil)
        httpController = HttpController()

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
        currentTemperature = temperature
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
            case 0.0..<20.0:
                //heatingLevelLabel.text = "None"
              updateHeatingLevel(heatingLevel: HeatingLevel.None)
            case 20.0..<50.0:
                //heatingLevelLabel.text = "33%"
              updateHeatingLevel(heatingLevel: HeatingLevel.Percent33)
            case 50.0..<75.0:
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

        setHeatingLevel(heatingLevel)

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
    
    func onHeatingLevelReceived (_ heatingLevel: HeatingLevel)
    {
        print("Heating level received from BLE device: \(heatingLevel)")

        receivedHeatingLevel = heatingLevel

        sliderUpdateCount += 1

        // This delay and cancellation workaround is needed
        // because BLE device doesn't update the heating level just once.
        // Instead it goes in cyclic manner as 0x03 -> 0x00 -> 0x01 -> 0x02,
        // so we need to delay the final update until all updates are done
        // and change it to the latest received value.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            sliderUpdateCount -= 1
            if (sliderUpdateCount != 0) {
                assert(sliderUpdateCount > 0)
                return
            }
            self.setHeatingLevel(receivedHeatingLevel)
        }
    }

    func setHeatingLevel (_ heatingLevel: HeatingLevel)
    {
        switch (heatingLevel)
        {
          case .None:
            heatingLevelLabel.text = "None"
            heatingLevelSlider.setValue(0.0, animated: false)
          case .Percent33:
            heatingLevelLabel.text = "33%"
            heatingLevelSlider.setValue(33.0, animated: false)
          case .Percent66:
            heatingLevelLabel.text = "66%"
            heatingLevelSlider.setValue(66.0, animated: false)
          case .Full:
            heatingLevelLabel.text = "Full"
            heatingLevelSlider.setValue(100.0, animated: false)
        }
    }

    func disconnectFromDevice () {
        if temperaturePeripheral != nil {
            // We have a connection to the device
            // but we are not subscribed to the Transfer Characteristic for some reason.
            // Therefore, we will just disconnect from the peripheral
            centralManager?.cancelPeripheralConnection(temperaturePeripheral!)
        }
    }

    @IBAction func syncButtonTouchedInside(_ sender: Any) {
        print("Sync button touched ...")
        httpController.syncDataWithHttpServer(temperature: currentTemperature)
    }
}
