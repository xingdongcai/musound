//
//  EventsViewController.swift
//  MuSound_2
//
//  Created by Harrison on 26/5/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import WebKit

class EventsViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    let url = URL(string:"https://www.meetup.com/melbourne-live-music-group/")
        //https://www.eventbrite.com/d/australia--melbourne/music/
    override func viewDidLoad() {
        super.viewDidLoad()
        let request = URLRequest(url:url!)
        webView.load(request)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
