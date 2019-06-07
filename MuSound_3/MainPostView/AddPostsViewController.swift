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


class AddPostsViewController: UIViewController, UITextFieldDelegate ,AVAudioRecorderDelegate,AVAudioPlayerDelegate{
    @IBOutlet weak var postDescTextField: UITextField!
    @IBOutlet weak var saveTestBTN: UIButton!
    
    
    @IBOutlet weak var recordBTN: UIButton!
    @IBOutlet weak var playBTN: UIButton!
    
    var soundRecorder: AVAudioRecorder!
    var soundPlayer: AVAudioPlayer!
    var recordingSession: AVAudioSession!
    var fileName :String = "audioFile.m4a"
    var storageReference = Storage.storage()
    var usersCollectionReference = Firestore.firestore().collection("users")
    var postsCollectionReference = Firestore.firestore().collection("posts")
    
    var userName:String!
    var imageURL:String!
    
    
    var ref: DocumentReference? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        postDescTextField.delegate = self
        
        saveTestBTN.isEnabled = false
        
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
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
  
    @IBAction func recordAction(_ sender: Any) {
        if recordBTN.titleLabel?.text == "Record" {
            soundRecorder.record()
            recordBTN.setTitle("Stop", for: .normal)
            playBTN.isEnabled = false
        } else {
            soundRecorder.stop()
            recordBTN.setTitle("Record", for: .normal)
            playBTN.isEnabled = false
            saveTestBTN.isEnabled = true
        }
        
    }
    
    @IBAction func playAction(_ sender: Any) {
        if playBTN.titleLabel?.text == "Play" {
            playBTN.setTitle("Stop", for: .normal)
            recordBTN.isEnabled = false
            setupPlayer()
            soundPlayer.play()
        } else {
            soundPlayer.stop()
            playBTN.setTitle("Play", for: .normal)
            recordBTN.isEnabled = false
        }
    }
    
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
        metadata.contentType = "audio/m4a"
        
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
        
        navigationController?.popViewController(animated: true)
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
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
        playBTN.setTitle("Play", for: .normal)
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
}




/* default user image
https://www.flaticon.com/free-icon/boy_145867
*/
