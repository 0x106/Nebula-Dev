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
    
    var sessionframeCounter: Int = 0
    
    let grid: WorldGrid = WorldGrid()
    
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
                
                self.grid.add(String(self.grid.markers.count - 3), position, isTrail: true)
            }
            
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
        
//        self.sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
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


class WorldGrid {
    
    var markers: [Marker] = [Marker]()
    var trailMarkers: [Marker] = [Marker]()
    var origin: Marker = Marker("*")
    var scale: Float = 0.1
    
    var edges: [SCNNode] = [SCNNode]()
    var trailEdges: [SCNNode] = [SCNNode]()
    
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
                                                                    radius: CGFloat(0.0005), lengthOffset: CGFloat(0.005), color: UIColor.magenta.withAlphaComponent(CGFloat(0.35))))
            origin.rootNode.addChildNode(edges[edges.count - 1])
        }
    }
    
    func add(_ _label: String, _ _position: SCNVector3, isTrail _isTrail: Bool) {
        if !_isTrail {
            let marker = Marker(_label)
            marker.rootNode.position = _position
            markers.append(marker)
            self.origin.rootNode.addChildNode(marker.rootNode)
        } else {
            let marker = Marker()
            marker.rootNode.position = _position
            trailMarkers.append(marker)
            self.origin.rootNode.addChildNode(marker.rootNode)
            
            if self.trailMarkers.count > 2 {
                trailEdges.append(SCNNode().buildLineInTwoPointsWithRotation(from: self.trailMarkers[self.trailMarkers.count-2].rootNode.position,
                                                                             to:   self.trailMarkers[self.trailMarkers.count-1].rootNode.position,
                                                                             radius: CGFloat(0.0005), lengthOffset: CGFloat(0.0), color: UIColor.magenta.withAlphaComponent(CGFloat(0.35))))
                self.origin.rootNode.addChildNode(trailEdges[trailEdges.count - 1])
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
        let sphere = SCNSphere(radius: 0.002)
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

