//
//  StarPathTableViewController.swift
//  Nebula
//
//  Created by Jordan Campbell on 24/02/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import UIKit
import ARKit
import SwiftyJSON
import Firebase

class StarPathTableViewController: UITableViewController {

    var metadata: JSON?
    var data: [StarPath] = [StarPath]()
    var labelToEdit: IndexPath!
    
    let textField = UITextField()
    let recognizer = UILongPressGestureRecognizer()
    let tap: UITapGestureRecognizer = UITapGestureRecognizer()
    
    var inRefresh: Bool = false
    
    var keys: Dictionary<Int, String> = Dictionary<Int, String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)

        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        textField.isHidden = true
        self.view.addSubview(textField)
        
        tap.addTarget(self, action: #selector(self.dismissKeyboard) )
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        self.refresh()
    }
    
    @IBAction func unwindToSceneList(sender: UIStoryboardSegue) {
        if let _ = sender.source as? ViewController {
            self.refresh()
        }
    }

    @objc func refresh() {
        if !self.inRefresh {
            self.inRefresh = true
            initMetadata(metadataCallback(_:))
        }
    }
    
    func metadataCallback(_ _metadata: JSON) {
        self.metadata = _metadata
        self.loadStarpaths()
        self.inRefresh = false
        self.refreshControl?.endRefreshing()
    }
    
    @objc func dismissKeyboard(gesture: UITapGestureRecognizer) {
        self.clearTextInput()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }

    func clearTextInput() {
        self.textField.text = ""
        self.textField.resignFirstResponder()
        if let index = self.labelToEdit {
            self.metadata![self.data[index.row].key]["displayname"].stringValue = self.data[index.row].displayname
            updateMetadata(self.metadata!)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StarPathTableViewCell", for: indexPath) as? StarPathTableViewCell else {
            fatalError("The dequeued cell is not an instance of StarPathTableViewCell.")
        }
        
        let starpath = self.data[indexPath.row]
        
        cell.nameLabel.text = starpath.displayname
        
        if self.metadata![starpath.key]["uploaded"] == "true" {
            cell.uploadButton.setImage(UIImage(named: "done"), for: .normal)
        } else {
            cell.uploadButton.setImage(UIImage(named: "upload"), for: .normal)
        }
        
        cell.photoImageView?.image = starpath.image
        cell.uploadButton.tag = indexPath.row
        cell.uploadButton.key = starpath.key
        cell.uploadButton.uid = self.metadata!["metauser"]["uid"].stringValue
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped ))
        
        // add it to the image view;
        cell.photoImageView?.addGestureRecognizer(tapGesture)
        // make sure imageView can be interacted with by user
        cell.photoImageView?.isUserInteractionEnabled = true

        return cell
    }
    
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            print("Image Tapped: \(gesture.view?.tag)")
            
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Mapping") as! DetectionViewController
            viewController.targetKey = "neuromancer"
            self.present(viewController, animated: false, completion: nil)
            
        }
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        self.data[self.labelToEdit!.row].updateDisplayname(textField.text!)
        self.tableView.reloadRows(at: [self.labelToEdit], with: UITableViewRowAnimation.none)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
 
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {            
        } else if editingStyle == .insert {
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let starpath = self.data[indexPath.row]
            
            let storage = Storage.storage()
            let storageRef = storage.reference().child(self.metadata!["metauser"]["uid"].stringValue).child(starpath.key).child(starpath.key+".zip")
            // Delete the file
            storageRef.delete { error in
                if let _ = error {
                } else {
                }
            }
            
            let fileManager = FileManager.default
            let deletePath = getFilePath(fileFolder: starpath.key, fileName: "")
            do {
                try fileManager.removeItem(atPath: deletePath)
            }
            catch _ as NSError {
            }
            
            self.metadata!.dictionaryObject?.removeValue(forKey: starpath.key)
            updateMetadata(self.metadata!)
            self.refresh()
            
        }
        
        let rename = UITableViewRowAction(style: .normal, title: "Rename") { (action, indexPath) in
            // rename item at indexPath
            self.labelToEdit = indexPath
            self.textField.becomeFirstResponder()
        }

        rename.backgroundColor = UIColor(red: 0x0D, green: 0x5C, blue: 0x63)
        
        return [delete, rename]
    }
    
    //MARK: Private Methods
    
    private func loadStarpaths() {
        
        self.data = [StarPath]()
                
        guard let _ = self.metadata else { return }
                
        var index = 0
        for (key, value) in self.metadata! {
            if key != "metauser" {
                
                let imagePath = getFilePath(fileFolder: key, fileName: value["displayimage"].stringValue)
                let img = UIImage(contentsOfFile: imagePath)!
                
                if let starpath = StarPath(key, value["displayname"].stringValue, value["uploaded"].stringValue, img) {//images[index % images.count]!) {
                    self.data.append(starpath)
                }
                index += 1
            }
        }
        
        print("Initialised \(self.data.count) starpaths")
        
        self.tableView.reloadData()
        
    }

}
