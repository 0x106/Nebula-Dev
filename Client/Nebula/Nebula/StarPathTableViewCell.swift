//
//  StarPathCell.swift
//  Nebula
//
//  Created by Jordan Campbell on 24/02/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import UIKit
import SwiftyJSON

class StarPathTableViewCell: UITableViewCell {
    
    //MARK: Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var uploadButton: NebulaButton!

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
        
        var data: JSON = JSON()
        var images: [UIImage] = [UIImage]()
        
        // get the path to the data
        let dirPath = getDocumentsDirectory()
        let filePath = NSURL(fileURLWithPath: dirPath).appendingPathComponent(self.uploadButton.key)?.path
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: filePath!)
         
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
                    
                    if let image = UIImage(contentsOfFile: __file) {
                        images.append(image)
                    }
                }
            }
            
        } catch {
            print("no available files")
        }
        
        // connect to database
        
        // send data
    }

}


class NebulaButton: UIButton {
    var key: String = ""
}
