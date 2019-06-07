//
//  RegisterViewController.swift
//  MuSound_2
//
//  Created by Harrison on 23/5/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController,UITextFieldDelegate {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var password2TextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var collectionReference = Firestore.firestore().collection("users")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        nextButton.layer.cornerRadius = 8
        emailTextField.delegate = self
        passwordTextField.delegate = self
        password2TextField.delegate = self
    }
    
    @IBAction func registerAccount(_ sender: Any) {
        guard let password = passwordTextField.text else {
            displayErrorMessage("Please enter a password")
            return
        }
        guard let password2 = password2TextField.text else {
            displayErrorMessage("Please enter a password")
            return
        }
        guard let email = emailTextField.text else {
            displayErrorMessage("Please enter an email address")
            return
        }
        if password != password2{
            displayErrorMessage("Please check password")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if error != nil {
                self.displayErrorMessage(error!.localizedDescription)
            }else{
                self.performSegue(withIdentifier: "toProfileSegue", sender: nil)
            }
            
        }
    }
    
    
    @IBAction func goBackToLogin(_ sender: Any) {
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
    func displayErrorMessage(_ errorMessage: String) {
        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
