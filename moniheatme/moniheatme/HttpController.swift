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
// https://b2b.krystian.com.pl/api/heating
//
// https://b2b.krystian.com.pl/api/motion

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

        // prepare json data
        let json: [String: Any] = ["apikey": ApiKey,
                                   "data": ["employee_code":userName,
                                            "temperature":String(temperature)]]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // create post request
        let url = URL(string: HeatingHttpEndPoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // insert json data to the request
        request.httpBody = jsonData

        print("JSON data:\(json)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
            if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                print("SUCCESS! response code:\(response.statusCode), full response:\(response)")
            } else {
                print("FAIL! full response:\(String(describing: response)))")
            }
        }

        task.resume()
    }
}
