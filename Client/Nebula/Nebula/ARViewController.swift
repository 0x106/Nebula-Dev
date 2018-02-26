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
import Firebase

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var sceneRecordCompletionButton: UIBarButtonItem!
    
    let recordbutton = UIButton()
    let starpathbutton = UIButton()
    var trackingReady: Bool = false
    var trackingON: Bool = false
    var dataWriteStarted: Bool = false
    var dataWriteComplete: Bool = false
    var jsonObject = [String:Any]()
    var recordStartTime: String?
    var recordKey: String = ""
    var frameCounter: Int = 0
    var atlasSession: ARSession = ARSession()
    var sessionframeCounter: Int = 0
    let grid: WorldGrid = WorldGrid()
    
    var metadata: JSON?
    
    var saveCurrentStarpath: Bool = true
    
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
        
        self.sceneRecordCompletionButton.isEnabled = false
//        self.sceneRecordCompletionButton.isEnabled = true
//        self.sceneRecordCompletionButton.tintColor = UIColor.blue
//        self.sceneRecordCompletionButton?.setTitleTextAttributes([NSAttributedStringKey.strokeColor : UIColor.blue], for: UIControlState.normal )
//        self.sceneRecordCompletionButton?.set
        
        self.metadata = initMetadata()
    }
    
    func writeData() {
        
        // we only want to write data when we have turned tracking off, and when there are no frames left to be written
        if self.frameCounter == 0 && self.trackingON == false {
            
            DispatchQueue.global(qos: .utility).async {
                
                print("Writing data:", self.frameCounter)
                
                let valid = JSONSerialization.isValidJSONObject(self.jsonObject)
                if valid {
                    let json = JSON(self.jsonObject)
                    
                    let dict = dataToDictionary(json)
                    
//                    let representation = json.rawString([.castNilToNSNull: true])
                    let representation = dict.description
                    let endtime = getCurrentTime()
                    let jsonFileName = endtime+".json"
//                    let jsonFilePath = getFilePath(fileFolder: self.recordStartTime!, fileName: jsonFileName)
                    let jsonFilePath = getFilePath(fileFolder: self.recordKey, fileName: jsonFileName)
                    do {
//                        try representation?.description.write(toFile: jsonFilePath, atomically: false, encoding: String.Encoding.utf8)
                        try representation.write(toFile: jsonFilePath, atomically: false, encoding: String.Encoding.utf8)
//                        saveData(json, self.metadata!["metauser"]["uid"].stringValue, self.recordKey)
                        
                        if var _ = self.metadata {
                            
                            let datum: JSON = [
                                
                                // keep a record of this in case we want to display the total
                                // recording time of this scene
                                "starttime": self.recordStartTime!,
                                "endtime": endtime,
                                
                                // initially just the folder (key) name - can be changed by the user
                                "filename": self.recordKey,
                                "dataname": jsonFileName,
                                "displayname": "Untitled",
                                
                                // has the data been uploaded to the cloud?
                                "uploaded": "false",
                                
                            ]
                            
                            self.metadata![self.recordKey] = datum
                            updateMetadata(self.metadata!)
                        }
                    }catch {
                        print("write json failed...")
                    }
                } else {
                    print("the json object to write is not valid")
                }
                
                DispatchQueue.main.async {
                    self.jsonObject.removeAll()
                    self.recordStartTime = nil
                    
                    self.sceneRecordCompletionButton.isEnabled = true
                    print(self.sceneRecordCompletionButton?.isEnabled)
                    
                    print("All data written and objects cleared.")
                }
            }
        } else {
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        if let state = self.sceneView.session.currentFrame?.camera.trackingState {
            switch(state) {
            case .normal:
                self.trackingReady = true
                sceneView.scene.rootNode.addChildNode(grid.origin.rootNode)
            case .notAvailable:
                break
            case .limited(let _):
                break
            }
        }
        
        // if we're ready to track
        if self.trackingReady {
            
            self.sessionframeCounter += 1
            let frequency = 10 // every ten frames add a position marker
            if self.sessionframeCounter % frequency == 0 {
                
                guard let transform = self.sceneView.session.currentFrame?.camera.transform else {return}
                let position = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                
                self.grid.add("", position, isstarpath: true)
                
//                var i = 0
//                for n in self.grid.starpathEdges {
//                    if i < self.grid.starpathEdges.count - 5 {
//                        n.isHidden = false
//                    } else {
//                        n.isHidden = true
//                    }
//                    i += 1
//                }
//
//                i = 0
//                for n in self.grid.markers {
//                    if i < self.grid.markers.count - 5 {
//                        n.rootNode.isHidden = false
//                    } else {
//                        n.rootNode.isHidden = true
//                    }
//                    i += 1
//                }
            }
            
            // show the button
            if self.recordbutton.isHidden {
                self.recordbutton.isHidden = false
                self.starpathbutton.isHidden = false
            }
            
            if self.recordbutton.isHighlighted {
                
                self.trackingON = true
                
                if self.recordStartTime == nil {
                    self.recordStartTime = getCurrentTime()
                    self.recordKey = uniqueKey()
                    print("Recording beginning at: \(self.recordStartTime! as String) with key: \(self .recordKey)")
                }
                
                self.frameCounter += 1      // we're adding a frame to the stack
                DispatchQueue.global(qos: .utility).async {
                
                    let jsonNode = currentFrameInfoToDic(currentFrame: frame)
                    self.jsonObject[jsonNode["imagename"] as! String] = jsonNode
                    
                    let json = JSON(jsonNode)
                    let representation = json.rawString([.castNilToNSNull: true])
                    
                    let image = UIImageJPEGRepresentation(pixelBufferToUIImage(pixelBuffer: frame.capturedImage), 0.25)!
                    
//                    let filePath = getFilePath(fileFolder: self.recordStartTime!, fileName: jsonNode["imagename"] as! String)
                    let filePath = getFilePath(fileFolder: self.recordKey, fileName: jsonNode["imagename"] as! String)
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
        
//        self.sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.automaticallyUpdatesLighting = true
        sceneView.showsStatistics = true
        
        // Run the view's session
        sceneView.session.run(configuration)
        
//        sceneView.session.pause()
    }
}

extension ViewController {
    func addButton() {
        
        let recordbuttonimg = UIImage(named: "buttonring")
        
        let size: Int = 64
//        let bx1 = self.sceneView.bounds.midX - CGFloat( size / 2 )
//        let by1 = self.sceneView.bounds.maxY - CGFloat( (recordbuttonimg?.cgImage?.height)! / 2 ) - CGFloat(size/2)
        let bx1 = CGFloat((self.sceneView.bounds.maxX/2) - 24)
        let by1 = CGFloat(self.sceneView.bounds.maxY - 80)
        
        recordbutton.frame = CGRect(x: bx1, y: by1, width: CGFloat(size), height: CGFloat(size))
        recordbutton.backgroundColor = .clear
        recordbutton.setImage(recordbuttonimg, for: .normal)
//        recordbutton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        recordbutton.layer.cornerRadius = 0.5 * recordbutton.bounds.size.width
        recordbutton.clipsToBounds = true
        self.sceneView.addSubview(recordbutton)
        self.recordbutton.isHidden = true
        
//        let bx2 = self.sceneView.bounds.midX - CGFloat( size / 2 )
//        let by2 = self.sceneView.bounds.maxY - CGFloat( (recordbuttonimg?.cgImage?.height)! / 2 ) - CGFloat(size/2)
        let bx2 = CGFloat((self.sceneView.bounds.midX/2) - 24)
        let by2 = CGFloat(self.sceneView.bounds.maxY - 80)
        
        let starpathbuttonimg = UIImage(named: "starpath")
        starpathbutton.frame = CGRect(x: bx2, y: by2, width: CGFloat(size), height: CGFloat(size))
        starpathbutton.backgroundColor = .clear
        starpathbutton.setImage(starpathbuttonimg, for: .normal)
        starpathbutton.addTarget(self, action: #selector(starpathButtonPressed), for: .touchUpInside)
        starpathbutton.layer.cornerRadius = 0.5 * starpathbutton.bounds.size.width
        starpathbutton.clipsToBounds = true
        self.sceneView.addSubview(starpathbutton)
        self.starpathbutton.isHidden = true
    }
    
    @objc func starpathButtonPressed() {
        if self.grid.canAdd {
//            self.grid.starpath.isHidden = false
            self.grid.canAdd = false
        } else {
            self.grid.canAdd = true
        }
    }
}


class WorldGrid {
    
    var markers: [Marker] = [Marker]()
    var starpathMarkers: [Marker] = [Marker]()
    var origin: Marker = Marker("*")
    var scale: Float = 0.1
    
    var starpath = SCNNode()
    
    var edges: [SCNNode] = [SCNNode]()
    var starpathEdges: [SCNNode] = [SCNNode]()
    
    var canAdd: Bool = false
    
    init() {
        markers.append(Marker("+X"))
        markers.append(Marker("+Y"))
        markers.append(Marker("-Z"))
        
        markers[0].rootNode.position = SCNVector3Make(1*scale, 0, 0)
        markers[1].rootNode.position = SCNVector3Make(0, 1*scale, 0)
        markers[2].rootNode.position = SCNVector3Make(0, 0, -(1*scale))
        
        for m in markers {
            origin.rootNode.addChildNode(m.rootNode)
            edges.append(SCNNode().buildLineInTwoPointsWithRotation(from: origin.rootNode.position, to: m.rootNode.position,
                                                                    radius: CGFloat(0.0015), lengthOffset: CGFloat(0.0), color: UIColor.magenta.withAlphaComponent(CGFloat(0.35))))
            origin.rootNode.addChildNode(edges[edges.count - 1])
        }
        
        self.origin.rootNode.addChildNode(self.starpath)
//        self.starpath.isHidden = true
    }
    
    func add(_ _label: String, _ _position: SCNVector3, isstarpath _isstarpath: Bool) {
        if !_isstarpath {
            let marker = Marker(_label)
            marker.rootNode.position = _position
            markers.append(marker)
            self.origin.rootNode.addChildNode(marker.rootNode)
        } else {
            
            if self.canAdd {
                let marker = Marker()
                marker.rootNode.position = _position
                starpathMarkers.append(marker)
                self.starpath.addChildNode(marker.rootNode)
                
                if self.starpathMarkers.count > 2 {
                    starpathEdges.append(SCNNode().buildLineInTwoPointsWithRotation(from: self.starpathMarkers[self.starpathMarkers.count-2].rootNode.position,
                                                                                 to:   self.starpathMarkers[self.starpathMarkers.count-1].rootNode.position,
                                                                                 radius: CGFloat(0.0005), lengthOffset: CGFloat(0.0), color: UIColor.magenta.withAlphaComponent(CGFloat(0.35))))
                    self.starpath.addChildNode(starpathEdges[starpathEdges.count - 1])
                }
            }
        }
    }
    
    
}

class Marker {
    var rootNode: SCNNode = SCNNode()
    var label: String = ""
    
    init(_ _label: String) {
        
        self.label = _label
        
        let depth: Float = 0.005
        
        // TEXT BILLBOARD CONSTRAINT
        //        let billboardConstraint = SCNBillboardConstraint()
        //        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // TEXT
        let text = SCNText(string: self.label, extrusionDepth: CGFloat(depth))
        let font = UIFont(name: "Arial", size: 0.2)
        text.font = font
        text.alignmentMode = kCAAlignmentCenter
        text.firstMaterial?.diffuse.contents = UIColor.magenta.withAlphaComponent(CGFloat(0.6))
        text.firstMaterial?.specular.contents = UIColor.white
        text.firstMaterial?.isDoubleSided = true
        text.chamferRadius = CGFloat(depth)
        
        // TEXT NODE
        let (minBound, maxBound) = text.boundingBox
        let textNode = SCNNode(geometry: text)
        textNode.name = "text"
        // Centre Node - to Centre-Bottom point
        textNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y - 0.05, depth/2)
        // Reduce default text size
        textNode.scale = SCNVector3Make(0.05, 0.05, 0.05)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.001)
        sphere.firstMaterial?.diffuse.contents = UIColor.white
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = "sphere"
        
        //        let sphereTranslation = SCNMatrix4MakeTranslation(0, -0.01, 0)
        //        sphereNode.transform = sphereTranslation
        
        // TEXT PARENT NODE
        let textNodeParent = SCNNode()
        textNodeParent.name = self.label
        textNodeParent.addChildNode(textNode)
        textNodeParent.addChildNode(sphereNode)
        //        textNodeParent.constraints = [billboardConstraint]
        
        self.rootNode = textNodeParent
    }
    
    init() {
        
        let depth: Float = 0.005
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.002)
        sphere.firstMaterial?.diffuse.contents = UIColor.white
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = "sphere"
        
        // TEXT PARENT NODE
        let textNodeParent = SCNNode()
        textNodeParent.name = self.label
        textNodeParent.addChildNode(sphereNode)
        
        self.rootNode = textNodeParent
    }
}















// end

