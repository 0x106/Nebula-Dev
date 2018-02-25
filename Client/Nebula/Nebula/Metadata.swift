//
//  Metadata.swift
//  Nebula
//
//  Created by Jordan Campbell on 26/02/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import Foundation
import SwiftyJSON
import Firebase
import FirebaseDatabase

let metadatafilename: String = "metadata.json"
func initMetadata() -> JSON {
    
    var _metadata = JSON()
    
    // get path
    let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let metadataPath = URL(fileURLWithPath: [documents, metadatafilename].joined(separator: "/"))
    
    // read
    do {
        let data = try Data(contentsOf: metadataPath)
        let response = try JSON(data: data)
        _metadata = response
        print("Read from metadata:")
        print(_metadata)
    } catch {
    }
    
    return _metadata
}

func updateMetadata(_ _metadata: JSON) {
    // get path
    let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let metadataPath = URL(fileURLWithPath: [documents, metadatafilename].joined(separator: "/"))
    
    print(_metadata)
    
    // write
    do {
        let data = try _metadata.rawData()
        try data.write(to: metadataPath)
        print("Wrote metadata to file.")
        
        var ref: DatabaseReference = Database.database().reference()
        let uid: String = _metadata["metauser"]["uid"].stringValue
        
        let metaDict = metadataToDictionary(_metadata)
        ref.child("users").child(uid).child("metadata").setValue(metaDict)
        
    } catch {
        print("Couldn't write to file: \(metadatafilename)")
    }
}


func saveData(_ _data: JSON) {
    print(_data)
    exit(EXIT_SUCCESS)
}


func metadataToDictionary(_ _metadata: JSON) -> Dictionary<String, Dictionary<String, String>> {
    var output = Dictionary<String, Dictionary<String, String>>()
    for datum in _metadata {
        var key = datum.0
        var value = datum.1.dictionaryObject as! Dictionary<String, String>
        output[key] = value
    }
    return output
}















// end
