//
//  Network.swift
//  Nebula
//
//  Created by Jordan Campbell on 25/02/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import Foundation
import Firebase

//func uploadImage(_ _path_: String, _ _uid: String, _ _key: String, _ _filename: String) {
//    
//    let _path = "file://\(_path_)"
//    
//    print("==== uploading image ====")
//    print("Path: \(_path)")
//    print("uid: \(_uid)")
//    print("key: \(_key)")
//    print("fname: \(_filename)")
//    
//    // retrieve image
//    
//    let storage = Storage.storage()
//    
//    // Create a root reference
//    let storageRef = storage.reference().child(_uid).child(_key).child(_filename)
//    
//    print("Reference: \(storageRef.description)")
//
//    // Create a reference to "mountains.jpg"
////    let mountainsRef = storageRef.child("mountains.jpg")
////
////    // Create a reference to 'images/mountains.jpg'
////    let mountainImagesRef = storageRef.child("images/mountains.jpg")
////
////    // While the file names are the same, the references point to different files
////    mountainsRef.name == mountainImagesRef.name;            // true
////    mountainsRef.fullPath == mountainImagesRef.fullPath;    // false
////
////    // Local file you want to upload
//    let localFile = URL(string: _path)!
//
//    // Create the file metadata
////    let metadata = StorageMetadata()
////    metadata.contentType = "image/jpeg"
////
//    // Upload file and metadata to the object 'images/mountains.jpg'
//    let uploadTask = storageRef.putFile(from: localFile)//, metadata: metadata)
//
//    // Listen for state changes, errors, and completion of the upload.
//    uploadTask.observe(.resume) { snapshot in
//        // Upload resumed, also fires when the upload starts
//    }
//
//    uploadTask.observe(.pause) { snapshot in
//        // Upload paused
//    }
//
//    uploadTask.observe(.progress) { snapshot in
//        // Upload reported progress
//        let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
//            / Double(snapshot.progress!.totalUnitCount)
//    }
//
//    uploadTask.observe(.success) { snapshot in
//        // Upload completed successfully
//        print("File: \(_filename) uploaded successfully.")
//    }
//
//    uploadTask.observe(.failure) { snapshot in
//        if let error = snapshot.error as? NSError {
//            
//            print("File: \(_filename) could not upload")
//            
//            switch (StorageErrorCode(rawValue: error.code)!) {
//            case .objectNotFound:
//                // File doesn't exist
//                break
//            case .unauthorized:
//                // User doesn't have permission to access file
//                break
//            case .cancelled:
//                // User canceled the upload
//                break
//
////                /* ... */
//
//            case .unknown:
//                // Unknown error occurred, inspect the server response
//                break
//            default:
//                // A separate error occurred. This is a good place to retry the upload.
//                break
//            }
//        }
//    }
//
//}

