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

class StarPathTableViewController: UITableViewController {

    var metadata: JSON?
    var data: [StarPath] = [StarPath]()
    var labelToEdit: IndexPath!
    
    let textField = UITextField()
    let recognizer = UILongPressGestureRecognizer()
    let tap: UITapGestureRecognizer = UITapGestureRecognizer()
    
    var inRefresh: Bool = false
    
//    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.re
        refreshControl = UIRefreshControl()
//        refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl!.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
//        tableView.addSubview(refreshControl!)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//         self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        textField.isHidden = true
        self.view.addSubview(textField)
        
        tap.addTarget(self, action: #selector(self.dismissKeyboard) )
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        self.refresh()
    }
    
    @IBAction func unwindToSceneList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? ViewController {
            
            // if a new scene was saved then we will need to re-load it.
            self.refresh()
        }
    }

    @objc func refresh() {
        // Code to refresh table view
        
//        self.refresh()
        if !self.inRefresh {
            self.inRefresh = true
            self.metadata = initMetadata()
            self.loadStarpaths()
            self.inRefresh = false
            self.refreshControl?.endRefreshing()
        }
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard(gesture: UITapGestureRecognizer) {
        self.clearTextInput()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\(self.data.count) rows in table")
        return self.data.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        self.labelToEdit = indexPath
//
//        // if we tap on a cell, then stop editing anything
//        if self.textField.isFirstResponder {
//            self.clearTextInput()
//        } else {
//            print("Label was pressed")
//            self.textField.becomeFirstResponder()
//        }
    }
    
    func clearTextInput() {
        self.textField.text = ""
        
        self.textField.resignFirstResponder()
        // update any changes to the metadata
        
        if let index = self.labelToEdit {
            print("Changed label for datum: \(self.data[index.row].key)")
            self.metadata![self.data[index.row].key]["displayname"].stringValue = self.data[index.row].displayname
            updateMetadata(self.metadata!)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StarPathTableViewCell", for: indexPath) as? StarPathTableViewCell else {
            fatalError("The dequeued cell is not an instance of StarPathTableViewCell.")
        }
        
        print("creating cell for: \(indexPath.row)")

        // Configure the cell...
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

        return cell
    }
    
//    @objc func labelPress(gesture: UILongPressGestureRecognizer) {
//
//        switch gesture.state {
//        case UIGestureRecognizerState.began:
//            break;
//        case UIGestureRecognizerState.ended:
//            print("Label was pressed")
//            self.textField.becomeFirstResponder()
//        default: break
//        }
//    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.data[self.labelToEdit!.row].updateDisplayname(textField.text!)
        self.tableView.reloadRows(at: [self.labelToEdit], with: UITableViewRowAnimation.none)
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
 
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    //MARK: Private Methods
    
    private func loadStarpaths() {
        
        print("Loading all starpaths")
        
        self.data = [StarPath]()
        
        let images = [UIImage(named: "moonbase"), UIImage(named: "nebula"), UIImage(named: "spacex")]
        
        guard let _ = self.metadata else { print("cannot load metadata"); return }
        
        print("\(self.metadata!.count) items found")
        
        var index = 0
        for datum in self.metadata! {
            
            let key = datum.0
            let value = datum.1
            
            if key != "metauser" {
                if let starpath = StarPath(key, value["displayname"].stringValue, value["uploaded"].stringValue, images[index % images.count]!) {
                    self.data.append(starpath)
                }
                index += 1
            }
        }
        
        print("\(self.data.count) items to display")
        print("================================")
        
        self.tableView.reloadData()
        
    }

}
