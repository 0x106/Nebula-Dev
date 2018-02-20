//
//  ViewController.swift
//  Nebula
//
//  Created by Jordan Campbell on 17/12/17.
//  Copyright © 2017 Atlas Reality. All rights reserved.
//
//  Note that this is based on someone else's code - need
//  to retrieve their copyright information
//
//

import UIKit
import SceneKit
import ARKit
import SwiftyJSON

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    let button = UIButton()
    
    var trackingReady: Bool = false
    var trackingON: Bool = false
    var dataWriteStarted: Bool = false
    var dataWriteComplete: Bool = false
    
    var jsonObject = [String:Any]()
    var recordStartTime: String?
    
    var frameCounter: Int = 0
    
    var atlasSession: ARSession = ARSession()
    var nebula: Nebula = Nebula()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        self.sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        //        atlasSession = ARSession()
        
        self.addButton()
    }
    
    func currentFrameInfoToDic(currentFrame: ARFrame) -> [String: Any] {
        
        let currentTime:String = String(format:"%f", currentFrame.timestamp)
        let imageName = currentTime + ".jpg"
        
        let jsonObject: [String: Any] = [
            "imagename": imageName,
            "timestamp": currentFrame.timestamp,
            "position": dictFromVector3(positionFromTransform(currentFrame.camera.transform)),
            "rotation": dictFromVector3(currentFrame.camera.eulerAngles)
//            "cameraTransform": arrayFromTransform(currentFrame.camera.transform),
//            "cameraIntrinsics": arrayFromTransform(currentFrame.camera.intrinsics),
//            "cameraProjection": arrayFromTransform(currentFrame.camera.projectionMatrix),
//            "imageResolution": [
//                "width": currentFrame.camera.imageResolution.width,
//                "height": currentFrame.camera.imageResolution.height
//            ],
//            "lightEstimate": currentFrame.lightEstimate?.ambientIntensity,
//            "ARPointCloud": [
//                "count": currentFrame.rawFeaturePoints?.points.count,
//                "points": arrayFromPointCloud(currentFrame.rawFeaturePoints)
//            ]
        ]
        
        return jsonObject
    }
    
    func writeData() {
        
        // we only want to write data when we have turned tracking off, and when there are no frames left to be written
        if self.frameCounter == 0 && self.trackingON == false {
            
            // extract the position and rotation of the camera
            
//            var data: [String : [String: Float]] = [String: [String: Float]]()
//            DispatchQueue.global(qos: .utility).async {
//                for (key, _value) in self.jsonObject {
//                    if let value = _value as? [String: Any] {
//                        let temp = [:]
//                        if let _currentPosition = value["cameraPos"] as? [String: Float],
//                           let _currentRotation = value["cameraEulerAngle"] as? [String: Float] {
////                            temp["position"]
//                        }
//                    }
//                }
            
//                data[key]["rotation"] = _currentRotation
//                data[key]["position"] = _currentPosition
                
//                print(data)
//            }
            
            DispatchQueue.global(qos: .utility).async {
                
                print("Writing data:", self.frameCounter)
                
                let valid = JSONSerialization.isValidJSONObject(self.jsonObject)
                if valid {
                    let json = JSON(self.jsonObject)
                    let representation = json.rawString([.castNilToNSNull: true])
                    
                    if let data = representation?.description {
                        self.nebula.sendData(data)
                    }
                    
                    let jsonFilePath = getFilePath(fileFolder: self.recordStartTime!, fileName: getCurrentTime()+".json")
                    do {
                        try representation?.description.write(toFile: jsonFilePath, atomically: false, encoding: String.Encoding.utf8)
                    }catch {
                        print("write json failed...")
                    }
                } else {
                    print("the json object to write is not valid")
                }
                self.jsonObject.removeAll()
                self.recordStartTime = nil
                
                print("All data written and objects cleared.")
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // check whether we can track anything
        //        if self.track
        if let state = self.sceneView.session.currentFrame?.camera.trackingState {
            switch(state) {
            case .normal:
                self.trackingReady = true
            case .notAvailable:
                break
            case .limited(let _):
                break
            }
        }
        
        // if we're ready to track
        if self.trackingReady {
            
            // show the button
            if self.button.isHidden {
                self.button.isHidden = false
            }
            
            if self.button.isHighlighted {
                
                self.trackingON = true
                
                if self.recordStartTime == nil {
                    self.recordStartTime = getCurrentTime()
                    print("Recording beginning at:", self.recordStartTime! as String)
                }
                
                self.frameCounter += 1      // we're adding a frame to the stack
                DispatchQueue.global(qos: .utility).async {
                    let jsonNode = self.currentFrameInfoToDic(currentFrame: frame)
                    self.jsonObject[jsonNode["imagename"] as! String] = jsonNode
                    let jpgImage = UIImageJPEGRepresentation(pixelBufferToUIImage(pixelBuffer: frame.capturedImage), 1.0)
                    
                    let filePath = getFilePath(fileFolder: self.recordStartTime!, fileName: jsonNode["imagename"] as! String)
                    
                    try? jpgImage?.write(to: URL(fileURLWithPath: filePath))
                    self.frameCounter -= 1  // removing a frame from the stack
                    
                    self.writeData()
                }
            } else if self.trackingON {
                self.trackingON = false
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension ViewController {
    func addButton() {
        
        let buttonring = UIImage(named: "buttonring")
        let size: Int = 64
        let bx = self.sceneView.bounds.midX - CGFloat( size / 2 )
        let by = self.sceneView.bounds.maxY - CGFloat( (buttonring?.cgImage?.height)! / 2 ) - CGFloat(size/2)
        
        button.frame = CGRect(x: bx, y: by, width: CGFloat(size), height: CGFloat(size))
        button.backgroundColor = .clear
        
        button.setImage(buttonring, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        self.sceneView.addSubview(button)
        
        self.button.isHidden = true
    }
    
    @objc func buttonPressed() {
        
    }
}

