//
//  UserDataViewController.swift
//  moniheatme
//
//  Created by Marek Forys on 31/10/2021.
//

import UIKit

class UserDataViewController: UIViewController
{
    @IBOutlet weak var userNameTextField: UITextField!

    @IBAction func onSetUserNameTouchUpInside(_ sender: Any) {
        print("Set button for User Name touched ...")
        if let userName = userNameTextField.text {
            print("User Name:\(userName)")

            if userName.isEmpty == false {
                let defaults = UserDefaults.standard
                defaults.set(userName, forKey: "UserName")
            }
        }
        _ = navigationController?.popToRootViewController(animated: true)
    }
}
