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
func initMetadata(_ _callback: @escaping (JSON) -> ()) {
    
    var localMetadata = JSON()

    // get path
    let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let metadataPath = URL(fileURLWithPath: [documents, metadatafilename].joined(separator: "/"))

    // read
    do {
        let data = try Data(contentsOf: metadataPath)
        let response = try JSON(data: data)
        localMetadata = response
    } catch {}
    
    let userID = Auth.auth().currentUser?.uid
    let ref: DatabaseReference = Database.database().reference()
    var cloudMetadata = JSON()
    
    ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
        if let data = snapshot.value as? NSDictionary {
            cloudMetadata = JSON(data)
            for (key, value) in cloudMetadata["metadata"] {
                if key != "metauser" {
                    if let scenePoints = value["modelObjects"].arrayObject as? [String] {
                        localMetadata[key]["modelObjects"].arrayObject = stringToMatrix(scenePoints)
                    }
                }
            }
            _callback(localMetadata)
        }
    }) { (error) in
        print(error.localizedDescription)
    }

}

func updateMetadata(_ _metadata: JSON) {
    // get path
    
    print("updating metadata")
    
    let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let metadataPath = URL(fileURLWithPath: [documents, metadatafilename].joined(separator: "/"))
    
    print(_metadata)
    
    // write
    do {
        let data = try _metadata.rawData()
        try data.write(to: metadataPath)
        
        let ref: DatabaseReference = Database.database().reference()
        let uid: String = _metadata["metauser"]["uid"].stringValue
        
        let metaDict = metadataToDictionary(_metadata)
        ref.child("users").child(uid).child("metadata").setValue(metaDict)
//        ref.child("users").child(uid).child("metadata").updateChildValues(metaDict)
        
    } catch {
        print("Error updating metadata")
    }
}


func saveData(_ _data: JSON, _ _uid: String, _ _sceneKey: String) {
    let data = dataToDictionary(_data)
    let ref: DatabaseReference = Database.database().reference()
    ref.child("users").child(_uid).child("data").child(_sceneKey).setValue(data)
}

func dataToDictionary(_ _data: JSON) -> String {
//    var outputString = "var jsondata = { \"data\": [{"
//    var outputString = "var jsondata = { \"data\": {"
    var outputString = "{ \"data\": {"
    let terminalString = "]}"

    var key_array = [String]()
    
    var count = 0
    let totalNum = _data.count
    
    for datum in _data {
        let key = datum.0
        var value = datum.1
        
        let position: Dictionary<String, Double> = [
            "x": value["position"]["x"].doubleValue,
            "y": value["position"]["y"].doubleValue,
            "z": value["position"]["z"].doubleValue
        ]
        
        let rotation: Dictionary<String, Double> = [
            "x": value["rotation"]["x"].doubleValue,
            "y": value["rotation"]["y"].doubleValue,
            "z": value["rotation"]["z"].doubleValue
        ]
    
        let intrinsics: Dictionary<String, Double> = [
            "m00": value["intrinsics"][0][0].doubleValue,
            "m01": value["intrinsics"][0][1].doubleValue,
            "m02": value["intrinsics"][0][2].doubleValue,
            
            "m10": value["intrinsics"][1][0].doubleValue,
            "m11": value["intrinsics"][1][1].doubleValue,
            "m12": value["intrinsics"][1][2].doubleValue,
            
            "m20": value["intrinsics"][2][0].doubleValue,
            "m21": value["intrinsics"][2][1].doubleValue,
            "m22": value["intrinsics"][2][2].doubleValue
        ]
        
//        outputString += "{"
        outputString += "\"\(key)\":{"
        outputString += "\"position\":" + position.description.replacingOccurrences(of: "[", with: "{").replacingOccurrences(of: "]", with: "}") + ","
        outputString += "\"rotation\":" + rotation.description.replacingOccurrences(of: "[", with: "{").replacingOccurrences(of: "]", with: "}") + ","
        outputString += "\"intrinsics\":" + intrinsics.description.replacingOccurrences(of: "[", with: "{").replacingOccurrences(of: "]", with: "}") + ","
        
        key_array.append(key)
        
        let datum_key = removeFileExtension(value["imagename"].stringValue)
        
        if count < totalNum-1 {
            outputString += "\"key\": \"\(datum_key)\"},"
        } else {
            outputString += "\"key\": \"\(datum_key)\"}"
        }
        count += 1
    }
    
    key_array.sort()
//    var key_list = "],\"keys\":["
//    var key_list = "}, \"keyFrame\":\(_keyframe), \"keys\":["
    var key_list = "}, \"keys\":["
    count = 0
    for var k in key_array {
        
        k = removeFileExtension(k)
        
        if count < key_array.count - 1 {
            key_list += "\"" + k + "\", "
        } else {
            key_list += "\"" + k + "\""
        }
        count += 1
    }
    
    outputString += key_list + terminalString
        
    return outputString
}

func removeFileExtension(_ _input: String) -> String {
    let output: String = String(_input.prefix(upTo: _input.index(of: ".")!))
    return output
}

func metadataToDictionary(_ _metadata: JSON) -> Dictionary<String, Dictionary<String, String>> {
    var output = Dictionary<String, Dictionary<String, String>>()
    for datum in _metadata {
        let key = datum.0
        let value = datum.1.dictionaryObject as! Dictionary<String, String>
        output[key] = value
    }
    return output
}















// end
