//
//  StartViewController.swift
//  MuSound_2
//
//  Created by Harrison on 4/5/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import Firebase


class StartViewController: UIViewController,UITextFieldDelegate {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var LoginButton: UIButton!
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        LoginButton.layer.cornerRadius = 8
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        handle = Auth.auth().addStateDidChangeListener( { (auth, user) in
            
            if user != nil {
                
                self.performSegue(withIdentifier: "loginSegue", sender: nil)
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    
    @IBAction func signinAccount(_ sender: Any) {
        guard let password = passwordTextField.text else {
            displayErrorMessage("Please enter a password")
            return
        }
        guard let email = emailTextField.text else {
            displayErrorMessage("Please enter an email address")
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if error != nil {
                self.displayErrorMessage(error!.localizedDescription)
            }
        }
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
    
        
        
    
    /*
    Reference: Week10 Lab Resources
    Supplementary - Firebase Authentication & Storage
 
    playButtonImage:
    https://www.iconfinder.com/search/?q=button
    */


