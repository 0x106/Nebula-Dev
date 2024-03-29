//
//  StarPath.swift
//  Nebula
//
//  Created by Jordan Campbell on 24/02/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import Foundation
import ARKit
import SwiftyJSON

class StarPath {
    
    var cameraData: [String:Any] = [String:Any]()
    var starttime: String = "" // the folder this data is saved in
    var displayname: String = ""
    var key: String = ""    // the
    var uploaded: Bool = false
    var endtime: String = ""
    var image: UIImage = UIImage()

    init?(_ _key: String, _ _displayname: String, _ _uploaded: String, _ _image: UIImage) {
        
        self.key = _key
        self.displayname = _displayname
        
        // TODO: change to bool true/false
        if _uploaded == "true" {
            self.uploaded = true
        }
        
        self.image = _image
    }
    
    func updateDisplayname(_ _text: String) {
        self.displayname = _text
    }
    
}

