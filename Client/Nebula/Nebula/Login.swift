//
//  Login.swift
//  Nebula
//
//  Created by Jordan Campbell on 25/02/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import Foundation
import ARKit
import Firebase
import GoogleSignIn
import SwiftyJSON

class LoginController: UIViewController, GIDSignInUIDelegate {
    
    var metadata: JSON?
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.metadata = initMetadata()
//        self.metadata = retrieveMetadata()
        
        GIDSignIn.sharedInstance().uiDelegate = self
//        GIDSignIn.sharedInstance().signIn()
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            
            if user != nil {
            
                if var _ = self.metadata {
                    if self.metadata!["metauser"]["uid"].stringValue == "" {
                        let metauser: JSON = [
                            "uid": user?.uid ?? "unknown"
                        ]
                        self.metadata!["metauser"] = metauser
                        updateMetadata(self.metadata!)
                    } else {
                        if let userID = user?.uid {
                            if self.metadata!["metauser"]["uid"].stringValue != userID {
                                fatalError("User ID doesn't match recorded value.")
                            }
                        }
                    }
                }
            
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "login_tableViewSegue", sender: self)
                }
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
}

class LogoutController: UIViewController {
    
    @IBAction func logout(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            do {
                try? Auth.auth().signOut()
                if let _ = Auth.auth().currentUser {
                } else {
                }
            }
        }
    }
    

}

