//
//  UserDetailViewController.swift
//  MuSound_2
//
//  Created by Harrison on 25/5/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import Firebase

class UserDetailViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    
    
    var storageReference = Storage.storage()
    var userCollectionReference = Firestore.firestore().collection("users")
    let userID = Auth.auth().currentUser!.uid
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.delegate = self
        
        //Set default image, if user didn't select own image, then use this image
        if let myImage: UIImage = UIImage(named:"boy"){
            imageView.image = myImage
        }
    }
    
    
    //Source: https://stackoverflow.com/questions/29887869/uiactionsheet-ios-swift
    //Show action sheet for user to set profile image,
    @IBAction func showAlert(_ sender: Any) {
        let alert = UIAlertController(title: "Set your profile picture", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default , handler:{ (UIAlertAction)in
            self.pictureFromCamera()
        }))
        alert.addAction(UIAlertAction(title: "Album", style: .default , handler:{ (UIAlertAction)in
            self.pictureFromAlbum()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
        }))
        
        self.present(alert, animated: true, completion: {
        })
    }
    
    func pictureFromCamera(){
        let imagePicker: UIImagePickerController = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            imagePicker.sourceType = .camera
        }
        else{
            imagePicker.sourceType = .savedPhotosAlbum
        }
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func pictureFromAlbum(){
        let imagePicker: UIImagePickerController = UIImagePickerController()
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func registerAccount(_ sender: Any) {
        guard let userName = userNameTextField.text else {
            displayErrorMessage("Please enter a name")
            return
        }
        //save user name and profile image to firebase
        self.userCollectionReference.document("\(userID)").setData(["userName":"\(userName)"], merge: true)
        savePhotoToFirebase()
        
        self.performSegue(withIdentifier: "registerFinishSegue", sender: nil)
        
    }

    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        
        let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
        imageView.image = pickedImage
    }
    
    
    
    func savePhotoToFirebase(){
        
        let image = imageView.image
        let userID = Auth.auth().currentUser!.uid
        
        //initiate image data
        var data = Data()
        data = (image?.jpegData(compressionQuality: 0.2))!
        
        //set  userID as user image file under UserID folder in Firebase Storage
        let imageRef = storageReference.reference().child("\(self.userID)/\(self.userID)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        imageRef.putData(data,metadata:metadata){(meta,error) in
            if error != nil{
            }else{
                imageRef.downloadURL{(url,error) in
                    guard let downloadURL = url else{
                        print("Download URL not found")
                        return
                    }
                    
                    //save image url to firestore
                    self.userCollectionReference.document("\(userID)").setData(["imageURL":"\(downloadURL)"], merge: true)
                }
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




/* Source: Lab 9 - offline gallery application
 */
