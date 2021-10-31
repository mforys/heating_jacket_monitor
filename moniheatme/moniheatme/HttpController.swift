//
//  HttpController.swift
//  moniheatme
//
//  Created by Marek Forys on 29/10/2021.
//

import Foundation

//Klucz api: DMdBStq23pDENzBGTjh3r4byXRYbqG0w
//
//Endpointy:
//
//https://b2b.krystian.com.pl/api/heating
//
//https://b2b.krystian.com.pl/api/motion

let ApiKey = "DMdBStq23pDENzBGTjh3r4byXRYbqG0w"
let HeatingHttpEndPoint = "https://b2b.krystian.com.pl/api/heating"
let MotionHttpEndPoint = "https://b2b.krystian.com.pl/api/motion"

class HttpController {
    func syncDataWithHttpServer(temperature:Int) {
        print("Let's sync data with HTTP server ...")

        let defaults = UserDefaults.standard

        guard let userName = defaults.string(forKey: "UserName") else {
            print("User Name is nil!")
            return
        }

        if userName.isEmpty {
            print("User Name is empty!")
            return
        }

        sendTemperatureDataToServerWithUserName(userName: userName, temperature: temperature)
    }

    func sendTemperatureDataToServerWithUserName(userName:String, temperature:Int) {
        print("Let's send temperature:\(temperature) to HTTP server, because we have already UserName:\(userName)")
    }
}
