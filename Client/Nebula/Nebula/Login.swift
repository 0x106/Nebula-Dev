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
//        GIDSignIn.sharedInstance().signIn()
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            
            print(user)
            
            if user != nil {
            
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
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
}

class LogoutController: UIViewController {
    
//    override func viewWillAppear(_ animated: Bool) {
//        print("Loading logout controller")
//    }
    
    @IBAction func logout(_ sender: Any) {
        print("logout")
        if let _ = Auth.auth().currentUser {
            do {
                try? Auth.auth().signOut()
                if let user = Auth.auth().currentUser {
                    
                } else {
                    print("logged out")
                }
//                let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            }
        }
    }
    

}

