//
//  AddPostsViewController.swift
//  MuSound_2
//
//  Created by Harrison on 4/5/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import AVFoundation
import CoreData


class AddPostsViewController: UIViewController, UITextFieldDelegate ,AVAudioRecorderDelegate,AVAudioPlayerDelegate{
    @IBOutlet weak var postDescTextField: UITextField!
    @IBOutlet weak var postBTN: UIButton!
    @IBOutlet weak var saveBTN: UIButton!
    @IBOutlet weak var recordBTN: UIButton!
    @IBOutlet weak var playBTN: UIButton!
    
    var soundRecorder: AVAudioRecorder!
    var soundPlayer: AVAudioPlayer!
    var recordingSession: AVAudioSession!
    
    let iconPlay :UIImage = UIImage(named: "playIcon")!
    let iconStop :UIImage = UIImage(named: "stopIcon")!
    let iconRecord :UIImage = UIImage(named:"recordIcon")!
    let iconStopRecord :UIImage = UIImage(named:"stopRecordIcon")!
    
    //set default audio file name
    var fileName :String = "audioFile.m4a"
    
    //Firebase reference
    var storageReference = Storage.storage()
    var usersCollectionReference = Firestore.firestore().collection("users")
    var postsCollectionReference = Firestore.firestore().collection("posts")
    
    var managedObjectContext: NSManagedObjectContext?
    
    var userName:String!
    var imageURL:String!

    override func viewDidLoad() {
        super.viewDidLoad()
        postDescTextField.delegate = self

        postBTN.isEnabled = false
        saveBTN.isEnabled = false
        
        //fetch user profile, preparing for posting
        fetchUserProfile()
        
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            try recordingSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.setupRecorder()
                        self.playBTN.isEnabled = false
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = appDelegate?.persistantContainer?.viewContext
    }
    
    
    //record audio: action depends on button image
    @IBAction func recordAction(_ sender: Any) {
        if recordBTN.currentImage!.isEqual(iconRecord) {
            soundRecorder.record()
            recordBTN.setImage(iconStopRecord, for: .normal)
            playBTN.isEnabled = false
        } else {
            soundRecorder.stop()
            recordBTN.setImage(iconRecord, for: .normal)
            playBTN.isEnabled = false
            postBTN.isEnabled = true
            saveBTN.isEnabled = true
        }
    }
    //play audio: action depends on button image
    @IBAction func playAction(_ sender: Any) {
        if playBTN.currentImage!.isEqual(iconPlay) {
            playBTN.setImage(iconStop, for: .normal)
            recordBTN.isEnabled = false
            setupPlayer()
            soundPlayer.play()
            
        } else {
            soundPlayer.stop()
            playBTN.setImage(iconPlay, for: .normal)
            recordBTN.isEnabled = false
        }
    }
    //post to firebase
    @IBAction func saveToFirebase(_ sender: Any) {
        guard let postDescription = postDescTextField.text else {
            displayErrorMessage("Please enter a post description")
            return
        }
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
        let date = UInt(Date().timeIntervalSince1970)
        
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            soundPlayer.delegate = self
            soundPlayer.prepareToPlay()
            soundPlayer.volume = 4.0
        } catch {
            print(error)
        }
        
        let userID = Auth.auth().currentUser!.uid
        let audioRef = storageReference.reference().child("\(userID)/\(date)")
        let metadata = StorageMetadata()
        metadata.contentType = "audio/x-m4a"
        
        audioRef.putFile(from: audioFilename, metadata: nil) { metadata, error in
            if error != nil{
                
            }else{
                audioRef.downloadURL{(url,error) in
                    guard let downloadURL = url else{
                        print("Download URL not found")
                        return
                    }
                    self.usersCollectionReference.document("\(userID)").collection("posts").document("\(date)").setData(["audioURL":"\(downloadURL)","postDescription":"\(postDescription)"], merge: true)
                    self.postsCollectionReference.document("\(date)").setData(["audioURL":"\(downloadURL)","postDescription":"\(postDescription)","userName":"\(self.userName!)","imageURL":"\(self.imageURL!)"], merge: true)
                }
            }
        }
        displayMessage("Audio has been posted!", "Success!")
    }
    //save to local storage by using core data to store audio file reference
    @IBAction func saveToLocal(_ sender: Any) {
        guard let postDescription = postDescTextField.text else {
            displayErrorMessage("Please enter a post description")
            return
        }
        
        let userID = Auth.auth().currentUser!.uid
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
        let date = UInt(Date().timeIntervalSince1970)

        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        
        if let pathComponent = url.appendingPathComponent("\(date)") {
            let fileManager = FileManager.default
            do{
                try fileManager.copyItem(at: audioFilename, to: pathComponent)
            }catch{
                print("Cannot copy item")
            }
            
            
            let newLocalPost = NSEntityDescription.insertNewObject(forEntityName: "PostMetaData", into: managedObjectContext!) as! PostMetaData
            
            newLocalPost.filename = "\(date)"
            newLocalPost.postDescription = postDescription
            newLocalPost.userID = userID
            do {
                try self.managedObjectContext?.save()
                displayMessage("Audio has been saved!", "Success!")
                navigationController?.popViewController(animated: true)
            } catch {
                displayErrorMessage("Could not save to database,Error")
            }
        }
        
    }
    

    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    //initialising recorder, preparing to record
    func setupRecorder() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
        let recordSetting = [ AVFormatIDKey : kAudioFormatAppleLossless,
                              AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                              AVEncoderBitRateKey : 320000,
                              AVNumberOfChannelsKey : 2,
                              AVSampleRateKey : 44100.2] as [String : Any]
        do {
            soundRecorder = try AVAudioRecorder(url: audioFilename, settings: recordSetting )
            soundRecorder.delegate = self
            soundRecorder.prepareToRecord()
        } catch {
            print(error)
        }
    }
    
    //initialising player, preparing to play
    func setupPlayer() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            soundPlayer.delegate = self
            soundPlayer.prepareToPlay()
            soundPlayer.volume = 4.0
        } catch {
            print(error)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        playBTN.isEnabled = true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordBTN.isEnabled = true
        playBTN.setImage(iconPlay, for: .normal)
    }
    
    
    
    //Display error message
    func displayErrorMessage(_ errorMessage: String) {
        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    //fetch user name and user imageURL from firebase
    func fetchUserProfile(){
        let userID = Auth.auth().currentUser!.uid
        let userImageRef = usersCollectionReference.document("\(userID)")
        userImageRef.getDocument { (document, error) in
            self.userName = (document!.data()!["userName"] as! String)
            self.imageURL = (document!.data()!["imageURL"] as! String)
        }
    }
    
    func displayMessage(_ message: String,_ title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title:"Dismiss",style:.default){(action) in
            self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
