//
//  LocalPostsViewController.swift
//  MuSound_2
//
//  Created by Harrison on 26/5/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData
import Firebase
import FirebaseFirestore

class LocalPostsViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,UIGestureRecognizerDelegate,AVAudioPlayerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var postDescriptions = [String]()
    var userNames = [String]()
    var postDates = [String]()
    var audioURLs = [String]()
    var imageURLs = [String]()

    var userName:String!
    var imageURL:String!
    
    //firebase and core data references
    let userID = Auth.auth().currentUser!.uid
    var storageReference = Storage.storage()
    var postsCollectionReference = Firestore.firestore().collection("posts")
    var usersCollectionReference = Firestore.firestore().collection("users")
    var managedObjectContext: NSManagedObjectContext?
    
    //define audio stuffs
    var soundPlayer: AVAudioPlayer!
    var audioSession: AVAudioSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        fetchUserProfile()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = appDelegate?.persistantContainer?.viewContext
        
        
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            audioSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        //self.setupRecorder()
                        print("session success!")
                    } else {
                        // failed to play!
                    }
                }
            }
        } catch {
            // failed to record!
        }
        
        //Handle long press gesture
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(LocalPostsViewController.handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.6
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.collectionView.addGestureRecognizer(lpgr)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        let filter = userID
        
        //fetch audio from file using core data
        do {
            let fetchRequest : NSFetchRequest<PostMetaData> = PostMetaData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: " userID == %@", filter)
        
            let postDataList = try managedObjectContext!.fetch(fetchRequest) as [PostMetaData]
            if(postDataList.count > 0) {
                for data in postDataList {
                    let fileName = data.filename!
                    let postDescription = data.postDescription!
                    if(postDates.contains(fileName)) {
                        print("Post already loaded in. Skipping post")
                        continue
                    }
                    
                    if let audioUrl = loadAudioData(fileName: fileName) {
                        self.postDates.append(fileName)
                        self.postDescriptions.append(postDescription)
                        self.audioURLs.append(audioUrl)
                        //self.collectionView!.reloadSections([0])
                    }
                }
                self.collectionView.reloadData()
            }
        } catch {
            print("Unable to fetch list of parties")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.postDescriptions.removeAll()
        self.postDates.removeAll()
        self.audioURLs.removeAll()
    }
    
    //load audio data from file name to url
    func loadAudioData(fileName: String) -> String? {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        var filePath:String?
        if let pathComponent = url.appendingPathComponent(fileName) {
            filePath = pathComponent.path
        }
        return  filePath
    }
    

    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postDescriptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "localCell", for: indexPath) as! LocalPostsCollectionViewCell
        
        cell.postDescription.text = postDescriptions[indexPath.row]
        cell.postDate.text = postDates[indexPath.row]
        
        cell.playBTN.tag = indexPath.row
        cell.playBTN.addTarget(self, action: #selector(self.playTapped(_:)), for:UIControl.Event.touchUpInside)
        cell.stopBTN.tag = indexPath.row
        cell.stopBTN.addTarget(self, action: #selector(self.stopTapped(_:)), for:UIControl.Event.touchUpInside)
        
        cellCustomView(cell: cell)
        return cell
    }
    
    
    
    
    @objc func playTapped(_ sender: UIButton!){
        let filename = postDates[sender.tag]
        setupPlayer(filename: filename)
        soundPlayer.play()
    }
    
    @objc func stopTapped(_ sender: UIButton!){
        let filename = postDates[sender.tag]
        setupPlayer(filename: filename)
        soundPlayer.pause()
    }
    
    func setupPlayer(filename:String) {
        let audioFilename = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            soundPlayer.delegate = self
            soundPlayer.prepareToPlay()
            soundPlayer.volume = 4.0
        } catch {
            print(error)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    

    //handle long press gesture with action sheet for user to post or delete audio
    //Source:https://stackoverflow.com/questions/29887869/uiactionsheet-ios-swift
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state != .ended else { return }
        
        UIDevice.vibrate()
        
        let point = gestureRecognizer.location(in: collectionView)
        
        if let indexPath = collectionView.indexPathForItem(at: point),
            let _ = collectionView.cellForItem(at: indexPath) {
            // do stuff with your cell, for example print the indexPath
            print(indexPath.row)
            
            //show alert
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            
            let action1 = UIAlertAction(title: "Delete", style: .default) { (action) in
                print("Delete action")
                self.deletePost(filename: self.postDates[indexPath.row])
                self.collectionView.reloadData()
            }
            let action2 = UIAlertAction(title: "Post", style: .default) { (action) in
                print("Post to firebase action")
                self.saveToFirebase(filename: self.postDates[indexPath.row], postDescription: self.postDescriptions[indexPath.row])
                self.collectionView.reloadData()
            }
            let action3 = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                print("Cencel action")
            }
            
            action1.setValue(UIColor.red, forKey: "titleTextColor")
            alert.addAction(action1)
            alert.addAction(action2)
            alert.addAction(action3)
            present(alert, animated: true, completion: nil)
            
        } else {
            print("Could not find index path")
        }
    }
    
    //delete local file and reference in core data
    func deletePost(filename:String){
        let fetchRequest : NSFetchRequest<PostMetaData> = PostMetaData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: " filename == %@", filename)
        
        do {
        let trySession = try managedObjectContext!.fetch(fetchRequest) as [PostMetaData]
            let objectToDelete = trySession[0] as NSManagedObject
            managedObjectContext?.delete(objectToDelete)
        do{
            try managedObjectContext?.save()
            print("core data delete success")
            }
        }catch{
            print(error)
        }
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent(filename)
        let fileManager = FileManager.default
        do{
            try fileManager.removeItem(at: audioFilename)
            print("delete file success:\(audioFilename)")
        }catch{
            print("cannot delete file")
        }
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

    
    func saveToFirebase(filename:String,postDescription:String){
        let date = UInt(Date().timeIntervalSince1970)
        let audioFilename = getDocumentsDirectory().appendingPathComponent(filename)
        
        let audioRef = storageReference.reference().child("\(userID)/\(date)")
        let metadata = StorageMetadata()
        
        metadata.contentType = "audio/x-m4a"
        
        audioRef.putFile(from: audioFilename, metadata: metadata) { metadata, error in
            if error != nil{
            }else{
                audioRef.downloadURL{(url,error) in
                    guard let downloadURL = url else{
                        print("Download URL not found")
                        return
                    }
                    self.usersCollectionReference.document("\(self.userID)").collection("posts").document("\(date)").setData(["audioURL":"\(downloadURL)","postDescription":"\(postDescription)"], merge: true)
                    self.postsCollectionReference.document("\(date)").setData(["audioURL":"\(downloadURL)","postDescription":"\(postDescription)","userName":"\(self.userName!)","imageURL":"\(self.imageURL!)"], merge: true)
                }
            }
        }

    }

    
    
    func cellCustomView(cell:UICollectionViewCell){
        cell.contentView.layer.cornerRadius = 4.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = false
        cell.layer.shadowColor = UIColor.gray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        cell.layer.cornerRadius = 30
        cell.layer.shadowRadius = 6.0
        cell.layer.shadowOpacity = 0.8
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
    }
   
}

//Vibrate when long press
//Source:https://www.hackingwithswift.com/example-code/system/how-to-make-the-device-vibrate
extension UIDevice {
    static func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
