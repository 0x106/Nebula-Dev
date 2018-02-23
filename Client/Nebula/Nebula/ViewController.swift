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
    
    var counter: Int = 0
    
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
        
        self.addButton()
    }
    
    func currentFrameInfoToDic(currentFrame: ARFrame) -> [String: Any] {
        
        let currentTime:String = String(format:"%f", currentFrame.timestamp)
        let imageName = currentTime + ".jpg"
        
        let jsonObject: [String: Any] = [
            "imagename": imageName,
            "timestamp": currentFrame.timestamp,
            "position": dictFromVector3(positionFromTransform(currentFrame.camera.transform)),
            "rotation": dictFromVector3(currentFrame.camera.eulerAngles),
            "transform": arrayFromTransform(currentFrame.camera.transform),
            "intrinsics": arrayFromTransform(currentFrame.camera.intrinsics),
            "projection": arrayFromTransform(currentFrame.camera.projectionMatrix),
            "resolution": [
                "width": currentFrame.camera.imageResolution.width,
                "height": currentFrame.camera.imageResolution.height
            ],
            "light": currentFrame.lightEstimate?.ambientIntensity,
            "pointcloud": [
                "count": currentFrame.rawFeaturePoints?.points.count,
                "points": arrayFromPointCloud(currentFrame.rawFeaturePoints)
            ]
        ]
        
        return jsonObject
    }
    
    func writeData() {
        
        // we only want to write data when we have turned tracking off, and when there are no frames left to be written
        if self.frameCounter == 0 && self.trackingON == false {
            
            DispatchQueue.global(qos: .utility).async {
                
                print("Writing data:", self.frameCounter)
                
                let valid = JSONSerialization.isValidJSONObject(self.jsonObject)
                if valid {
                    let json = JSON(self.jsonObject)
                    let representation = json.rawString([.castNilToNSNull: true])
                    
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
                exit(EXIT_SUCCESS)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
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
                    
                    let json = JSON(jsonNode)
                    let representation = json.rawString([.castNilToNSNull: true])
                    
                    let image = UIImageJPEGRepresentation(pixelBufferToUIImage(pixelBuffer: frame.capturedImage), 0.25)!
                    
                    let filePath = getFilePath(fileFolder: self.recordStartTime!, fileName: jsonNode["imagename"] as! String)
                    try? image.write(to: URL(fileURLWithPath: filePath))
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
        
        self.sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.automaticallyUpdatesLighting = true
        sceneView.showsStatistics = true
        
        // Run the view's session
        sceneView.session.run(configuration)
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

