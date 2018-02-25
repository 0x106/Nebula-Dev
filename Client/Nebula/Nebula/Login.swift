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
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
        
        print("LoginController sign in")
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            
            print("user: \(user?.uid)")
            
            if var _ = self.metadata {
                if self.metadata!["metauser"].stringValue == "" {
                    let metauser: JSON = [
                        "uid": user?.uid ?? "unknown"
                    ]
                    self.metadata!["metauser"] = metauser
                    updateMetadata(self.metadata!)
                } else {
                    if self.metadata!["metauser"].stringValue != user?.uid {
                        fatalError("User ID doesn't match recorded value.")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "login_tableViewSegue", sender: self)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
//        do {
//            try Auth.auth().signOut()
//        } catch {
//
//        }
    }
    
}

