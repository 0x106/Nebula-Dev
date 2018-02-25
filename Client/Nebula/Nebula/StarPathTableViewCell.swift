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
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func uploadButtonTapped(_ sender: Any) {
        print("pressed button: \(self.uploadButton.tag)")
        
        self.metadata = initMetadata()
        
        var data: JSON = JSON()
        var images: [UIImage] = [UIImage]()
        var uploadCount = 0
        
        var failure: Bool = false
        
        // get the path to the data
        let dirPath = getDocumentsDirectory()
        let filePath = NSURL(fileURLWithPath: dirPath).appendingPathComponent(self.uploadButton.key)?.path
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: filePath!)
            
            self.uploadButton.setImage(UIImage(named: "hourglass"), for: .normal)
            
            self.numImagesToUpload = 1//files.count
         
            // read the data into local variable
            for fname in files {
                
                let __file = [filePath!, fname].joined(separator: "/")
                
                if fname.hasSuffix("json") {
                    
                    do {
                        let __data = try Data(contentsOf:  URL(fileURLWithPath: __file))
                        data = try JSON(data: __data)
                        
                    } catch {
                        print("couldn't read json data")
                    }
                    
                } else {
                    if uploadCount < 1 {
                        uploadImage(__file, self.uploadButton.uid, self.uploadButton.key, fname)
                    }
                    uploadCount += 1
                }
            }
            
        } catch {
            print("no available files")
        }
    }

    func uploadImage(_ _path_: String, _ _uid: String, _ _key: String, _ _filename: String) {
        
        let _path = "file://\(_path_)"
        
//        print("==== uploading image ====")
//        print("Path: \(_path)")
//        print("uid: \(_uid)")
//        print("key: \(_key)")
//        print("fname: \(_filename)")
        
        let storage = Storage.storage()
        
        // Create a root reference
        let storageRef = storage.reference().child(_uid).child(_key).child(_filename)
    
        //    // Local file you want to upload
        let localFile = URL(string: _path)!
        
        // Upload file and metadata to the object 'images/mountains.jpg'
        let uploadTask = storageRef.putFile(from: localFile)//, metadata: metadata)
        
        // Listen for state changes, errors, and completion of the upload.
        uploadTask.observe(.resume) { snapshot in
            // Upload resumed, also fires when the upload starts
        }
        
        uploadTask.observe(.pause) { snapshot in
            // Upload paused
        }
        
        uploadTask.observe(.progress) { snapshot in
            // Upload reported progress
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)
        }
        
        uploadTask.observe(.success) { snapshot in
            // Upload completed successfully
            print("File: \(_filename) uploaded successfully.")
            self.imageUploadCounter += 1
            self.imageUploadAttempts += 1
            
            if self.imageUploadAttempts == self.numImagesToUpload {
                print("Successfully uploaded \(self.imageUploadCounter) of \(self.numImagesToUpload) images")
                self.uploadButton.setImage(UIImage(named: "done"), for: .normal)
                
                // write to the metadata
                if let _ = self.metadata {
                    
                    self.metadata![self.uploadButton.key]["uploaded"].stringValue = "true"
                    print("======================")
                    print(self.metadata!)
                    print("======================")
                    updateMetadata(self.metadata!)
                    
                }
                
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as? NSError {
                
                print("File: \(_filename) could not upload")
                self.imageUploadAttempts += 1
                if self.imageUploadAttempts == self.numImagesToUpload {
                    print("Successfully uploaded \(self.imageUploadCounter) of \(self.numImagesToUpload) images")
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
