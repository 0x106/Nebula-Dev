//
//  StarPathCell.swift
//  Nebula
//
//  Created by Jordan Campbell on 24/02/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import UIKit
import SwiftyJSON
import Firebase
import Zip

class StarPathTableViewCell: UITableViewCell {
    
    //MARK: Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var uploadButton: NebulaButton!
    
    var imageUploadCounter: Int = 0
    var numImagesToUpload: Int = 0
    var imageUploadAttempts: Int = 0 // success + failure
    
    var metadata: JSON?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func uploadButtonTapped(_ sender: Any) {
        
        self.metadata = initMetadata()
        
        // get the path to the data
        let dirPath = getDocumentsDirectory()
        let filePath = NSURL(fileURLWithPath: dirPath).appendingPathComponent(self.uploadButton.key)?.path
        var zipPath: URL!
        do {
            self.uploadButton.setImage(UIImage(named: "hourglass"), for: .normal)
            zipPath = try Zip.quickZipFiles([URL(fileURLWithPath: filePath!)], fileName: self.uploadButton.key) // Zip
            
            uploadZip(zipPath.absoluteString, self.uploadButton.uid, self.uploadButton.key, self.uploadButton.key+".zip")
        } catch {
        }
    }
    
    func uploadZip(_ _path_: String, _ _uid: String, _ _key: String, _ _filename: String) {
        let _path = "file://\(_path_)"
        let storage = Storage.storage()
        let storageRef = storage.reference().child(_uid).child(_key).child(_filename)
        let localFile = URL(string: _path)!
        let uploadTask = storageRef.putFile(from: localFile)
        uploadTask.observe(.success) { snapshot in
            self.uploadButton.setImage(UIImage(named: "done"), for: .normal)
            
            // write to the metadata
            if let _ = self.metadata {
                
                self.metadata![self.uploadButton.key]["uploaded"].stringValue = "true"
                updateMetadata(self.metadata!)
                
            }
        }
        uploadTask.observe(.failure) { snapshot in
        }
    }

    func uploadImage(_ _path_: String, _ _uid: String, _ _key: String, _ _filename: String) {
        
        let _path = "file://\(_path_)"
        let storage = Storage.storage()
        let storageRef = storage.reference().child(_uid).child(_key).child(_filename)
        let localFile = URL(string: _path)!
        let uploadTask = storageRef.putFile(from: localFile)
        
        uploadTask.observe(.resume) { snapshot in
        }
        
        uploadTask.observe(.pause) { snapshot in
        }
        
        uploadTask.observe(.progress) { snapshot in
//            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
//                / Double(snapshot.progress!.totalUnitCount)
        }
        
        uploadTask.observe(.success) { snapshot in
            self.imageUploadCounter += 1
            self.imageUploadAttempts += 1
            
            if self.imageUploadAttempts == self.numImagesToUpload {
                self.uploadButton.setImage(UIImage(named: "done"), for: .normal)
                
                // write to the metadata
                if let _ = self.metadata {
                    
                    self.metadata![self.uploadButton.key]["uploaded"].stringValue = "true"
                    updateMetadata(self.metadata!)
                    
                }
                
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as NSError? {
                
                self.imageUploadAttempts += 1
                if self.imageUploadAttempts == self.numImagesToUpload {
                    self.uploadButton.setImage(UIImage(named: "done"), for: .normal)
                }
                
                switch (StorageErrorCode(rawValue: error.code)!) {
                case .objectNotFound:
                    // File doesn't exist
                    break
                case .unauthorized:
                    // User doesn't have permission to access file
                    break
                case .cancelled:
                    // User canceled the upload
                    break
                    
                case .unknown:
                    // Unknown error occurred, inspect the server response
                    break
                default:
                    // A separate error occurred. This is a good place to retry the upload.
                    break
                }
            }
        }
        
    }
}


class NebulaButton: UIButton {
    var key: String = ""
    var uid: String = ""
}
