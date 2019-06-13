//
//  FirstViewController.swift
//  MuSound_2
//
//  Created by Harrison on 4/5/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import AVFoundation

class MainViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,UIGestureRecognizerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var audioPlayer: AVPlayer?
    
    let db = Firestore.firestore()
    var storageReference = Storage.storage()
    let userImagesRef = Firestore.firestore().collection("users").document("\(Auth.auth().currentUser!.uid)")
    let userID = Auth.auth().currentUser!.uid
    
    var postDescriptions = [String]()
    var userNames = [String]()
    var postDates = [String]()
    var audioURLs = [String]()
    var images = [UIImage]()
    var imageURLs = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MainViewController.handleLongPress(_:)))
        lpgr.minimumPressDuration = 1
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.collectionView.addGestureRecognizer(lpgr)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        
        db.collection("posts").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents
                {
                    self.postDescriptions.insert(document.data()["postDescription"] as! String,at:0)
                    self.userNames.insert(document.data()["userName"] as! String,at:0)
                    self.imageURLs.insert(document.data()["imageURL"] as! String,at:0)
                    self.audioURLs.insert(document.data()["audioURL"] as! String,at:0)
                    self.postDates.insert(document.documentID,at:0)
                }
                self.collectionView.reloadData()
            }
        }
        
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.postDescriptions.removeAll()
        self.userNames.removeAll()
        self.imageURLs.removeAll()
        self.images.removeAll()
        self.audioURLs.removeAll()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postDescriptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MainCollectionViewCell
        
        cell.postDescription.text = postDescriptions[indexPath.row]
        cell.userName.text = userNames[indexPath.row]
        cell.postDate.text = postDates[indexPath.row]
        
        cell.playBTN.tag = indexPath.row
        
        cell.playBTN.addTarget(self, action: #selector(self.playTapped(_:)), for:UIControl.Event.touchUpInside)
        
        //Get user profileimage from firebase
        //Source:Firebase documentation
        self.storageReference.reference(forURL: imageURLs[indexPath.row]).getData(maxSize: 5*1024*1024, completion: { (data, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
            
                cell.userImage.image = UIImage(data: data!)
                cell.userImage.layer.cornerRadius = 40
            }})
        
        //
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
        
        return cell
        
    }
    
    @objc func playTapped(_ sender: UIButton!){
        
        let audioString = audioURLs[sender.tag]
        print("This is audioURL: \(audioURLs[sender.tag])")
        print(sender.tag)
        let audioURL = URL(string: audioString)!
        audioPlayer = AVPlayer(url: audioURL)
        
        let quarterOfASec = CMTimeMake(value: 1, timescale: 4)
        audioPlayer?.addPeriodicTimeObserver(forInterval: quarterOfASec, queue: DispatchQueue.main, using: { (time) in})
        print("playAudio success")
        audioPlayer?.play()
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state != .ended else { return }
        
        let point = gestureRecognizer.location(in: collectionView)
        
        if let indexPath = collectionView.indexPathForItem(at: point),
            let cell = collectionView.cellForItem(at: indexPath) {
            // do stuff with your cell, for example print the indexPath
            print(indexPath.row)
            
            //show alert
            let alert = UIAlertController(title: "Action", message: "after long press", preferredStyle: .alert)
            
            let action1 = UIAlertAction(title: "Delete?", style: .default) { (action) in
                print("Delete action")
            }
            let action2 = UIAlertAction(title: "Post?", style: .default) { (action) in
                print("Post to firebase action")
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
    
    /*
     UIButton Action Stuff
        https://stackoverflow.com/questions/41456441/how-to-add-uibutton-action-in-a-collection-view-cell
     Custom CollectionView Cell
        https://github.com/rileydnorris/cardLayoutSwift
     */
    
}

