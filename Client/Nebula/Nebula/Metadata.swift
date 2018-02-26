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


func saveData(_ _data: JSON, _ _uid: String, _ _sceneKey: String) {
    let data = dataToDictionary(_data)
    var ref: DatabaseReference = Database.database().reference()
    ref.child("users").child(_uid).child("data").child(_sceneKey).setValue(data)
}

func dataToDictionary(_ _data: JSON) -> Dictionary<String, Dictionary<String, Dictionary<String, String>>> {
    var output = Dictionary<String, Dictionary<String, Dictionary<String, String>>>()
    
//    print("===============================")
    for datum in _data {
        var key = datum.0
        var value = datum.1
        
//        key = String(key.prefix(13)).replacingOccurrences(of: ".", with: "_")
        
//        print(value)
        
        let position: Dictionary<String, String> = [
            "x": value["position"]["x"].stringValue,
            "y": value["position"]["y"].stringValue,
            "z": value["position"]["z"].stringValue
        ]
        
        let rotation: Dictionary<String, String> = [
            "x": value["rotation"]["x"].stringValue,
            "y": value["rotation"]["y"].stringValue,
            "z": value["rotation"]["z"].stringValue
        ]
        
        let resolution: Dictionary<String, String> = [
            "width": value["position"]["width"].stringValue,
            "height": value["position"]["height"].stringValue
        ]
        
        let imagename: Dictionary<String, String> = [
            "imagename": value["imagename"].stringValue
        ]
        
        let timestamp: Dictionary<String, String> = [
            "timestamp": value["timestamp"].stringValue
        ]
        
        let projection: Dictionary<String, String> = [
            "m00": value["projection"][0][0].stringValue,
            "m01": value["projection"][0][1].stringValue,
            "m02": value["projection"][0][2].stringValue,
            "m03": value["projection"][0][3].stringValue,
            
            "m10": value["projection"][1][0].stringValue,
            "m11": value["projection"][1][1].stringValue,
            "m12": value["projection"][1][2].stringValue,
            "m13": value["projection"][1][3].stringValue,
            
            "m20": value["projection"][2][0].stringValue,
            "m21": value["projection"][2][1].stringValue,
            "m22": value["projection"][2][2].stringValue,
            "m23": value["projection"][2][3].stringValue,
            
            "m30": value["projection"][3][0].stringValue,
            "m31": value["projection"][3][1].stringValue,
            "m32": value["projection"][3][2].stringValue,
            "m33": value["projection"][3][3].stringValue
        ]
        
        let transform: Dictionary<String, String> = [
            "m00": value["transform"][0][0].stringValue,
            "m01": value["transform"][0][1].stringValue,
            "m02": value["transform"][0][2].stringValue,
            "m03": value["transform"][0][3].stringValue,
            
            "m10": value["transform"][1][0].stringValue,
            "m11": value["transform"][1][1].stringValue,
            "m12": value["transform"][1][2].stringValue,
            "m13": value["transform"][1][3].stringValue,
            
            "m20": value["transform"][2][0].stringValue,
            "m21": value["transform"][2][1].stringValue,
            "m22": value["transform"][2][2].stringValue,
            "m23": value["transform"][2][3].stringValue,
            
            "m30": value["transform"][3][0].stringValue,
            "m31": value["transform"][3][1].stringValue,
            "m32": value["transform"][3][2].stringValue,
            "m33": value["transform"][3][3].stringValue
        ]
        
        let intrinsics: Dictionary<String, String> = [
            "m00": value["intrinsics"][0][0].stringValue,
            "m01": value["intrinsics"][0][1].stringValue,
            "m02": value["intrinsics"][0][2].stringValue,
            
            "m10": value["intrinsics"][1][0].stringValue,
            "m11": value["intrinsics"][1][1].stringValue,
            "m12": value["intrinsics"][1][2].stringValue,
            
            "m20": value["intrinsics"][2][0].stringValue,
            "m21": value["intrinsics"][2][1].stringValue,
            "m22": value["intrinsics"][2][2].stringValue
        ]
        
        output[key] = Dictionary<String, Dictionary<String, String>>()
        output[key]!["position"] = position
        output[key]!["rotation"] = rotation
        output[key]!["resolution"] = resolution
        output[key]!["imagename"] = imagename
        output[key]!["timestamp"] = timestamp
        output[key]!["projection"] = projection
        output[key]!["transform"] = transform
        output[key]!["intrinsics"] = intrinsics
    
//        print(output)
//        print("===============================")
//        return
    }
    
    print(output)
    
    return output
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
