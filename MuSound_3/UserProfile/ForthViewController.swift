//
//  FourthViewController.swift
//  MuSound_2
//
//  Created by Harrison on 4/5/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
import FirebaseFirestore

class FourthViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userNameTextView: UILabel!
    @IBOutlet weak var postTotal: UILabel!
    
    
    var userCollectionReference = Firestore.firestore().collection("users")
    var storageReference = Storage.storage()
    let db = Firestore.firestore()
    
    var postDescriptions = [String]()
    var audioURLs = [String]()
    var postDates = [String]()
    
    var audioPlayer: AVPlayer?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImage.image = UIImage(named:"profile1")
        profileImage.layer.cornerRadius = 40
        profileImage.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let userID = Auth.auth().currentUser!.uid
        
        //get user name from firestore
        let userInfoRef = userCollectionReference.document("\(userID)")
        userInfoRef.getDocument { (document, error) in
            //if let document = document, document.exists {
            if let document = document, let _ = document.data()!["userName"] {
                let userName = document.data()!["userName"] as! String
                self.userNameTextView.text = userName
            } else {
                print("User Name does not exist")
            }
        }

        userCollectionReference.document("\(userID)").collection("posts").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents
                {
                    self.postDescriptions.append(document.data()["postDescription"] as! String)
                    self.audioURLs.append(document.data()["audioURL"] as! String)
                    self.postDates.append(document.documentID)
                }
                self.collectionView.reloadData()
            }
        }
        
        
        
        //Get user profileimage from firebase
        //Source:Firebase documentation
        let userImagesRef = userCollectionReference.document("\(userID)")
        userImagesRef.getDocument { (document, error) in
            //if let document = document, document.exists {
            if let document = document, let _ = document.data()!["imageURL"] {
                let imageURL = document.data()!["imageURL"] as! String
                print("Image URL: \(imageURL)")
                
                self.storageReference.reference(forURL: imageURL).getData(maxSize: 5*1024*1024, completion: { (data, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        let image = UIImage(data: data!)
                        
                        self.profileImage.image = image
                        
                    }})
            } else {
                print("Image URL does not exist")
            }
        }
        
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.postDescriptions.removeAll()
        self.postDates.removeAll()
        self.audioURLs.removeAll()
    }
    
    
    
    @IBAction func logoutTapped(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        }catch{}
        //self.dismiss(animated: true, completion: nil)
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        postTotal.text = "\(self.postDescriptions.count) posts"
        return postDescriptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as! ProfileCollectionViewCell
        cell.audioDes.text = postDescriptions[indexPath.row]
        cell.postDate.text = postDates[indexPath.row]
        
        cell.playBTN.tag = indexPath.row
        cell.playBTN.addTarget(self, action: #selector(self.playTapped(_:)), for:UIControl.Event.touchUpInside)
        
        
        //custom cell design:
        cell.contentView.layer.cornerRadius = 4.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = false
        cell.layer.shadowColor = UIColor.gray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        cell.layer.shadowRadius = 6.0
        cell.layer.shadowOpacity = 1.0
        cell.layer.cornerRadius = 20
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        return cell
    }
    

    

    
    
    
    
    
    

    @objc func playTapped(_ sender: UIButton!){
        
        let audioString = audioURLs[sender.tag]
        let audioURL = URL(string: audioString)!
        audioPlayer = AVPlayer(url: audioURL)
        
        let quarterOfASec = CMTimeMake(value: 1, timescale: 4)
        audioPlayer?.addPeriodicTimeObserver(forInterval: quarterOfASec, queue: DispatchQueue.main, using: { (time) in})
        print("playAudio success")
        audioPlayer?.play()
    }
    
}

/*
Custom CollectionView Cell
    https://github.com/rileydnorris/cardLayoutSwift
UIButton Action Stuff
 https://stackoverflow.com/questions/41456441/how-to-add-uibutton-action-in-a-collection-view-cell
*/
