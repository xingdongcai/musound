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
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var galleryButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    
    
    
    var storageReference = Storage.storage()
    var userCollectionReference = Firestore.firestore().collection("users")
    let userID = Auth.auth().currentUser!.uid
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameTextField.delegate = self
        cameraButton.layer.cornerRadius = 8
        galleryButton.layer.cornerRadius = 8
        registerButton.layer.cornerRadius = 8
        
        
        
        let myImage: UIImage = UIImage(named:"boy")!
        imageView.image = myImage
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    
    
    
    @IBAction func photoFromCamera(_ sender: Any) {
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
    
    @IBAction func photoFromGallery(_ sender: Any) {
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
        self.userCollectionReference.document("\(userID)").setData(["userName":"\(userName)"], merge: true)
        savePhotoToFirebase()
        
        self.performSegue(withIdentifier: "registerFinishSegue", sender: nil)
        
    }
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
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
        var data = Data()
        data = (image?.jpegData(compressionQuality: 0.2))!
        
        let imageRef = storageReference.reference().child("\(userID)/\(userID)")
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
                    self.userCollectionReference.document("\(userID)").setData(["imageURL":"\(downloadURL)"], merge: true)
                    Firestore.firestore().collection("posts")
                }
            }
        }
        
        //        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        //        let url = NSURL(fileURLWithPath: path)
        //
        //        if let pathComponent = url.appendingPathComponent("\(userID)") {
        //            let filePath = pathComponent.path
        //            let fileManager = FileManager.default
        //            fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
        //        }
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




/* Reference: Lab 9 - offline gallery application
 */
