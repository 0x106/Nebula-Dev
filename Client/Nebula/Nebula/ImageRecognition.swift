//
//  ImageRecognition.swift
//  Nebula
//
//  Created by Jordan Campbell on 15/05/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import ARKit
import SwiftyJSON

class DetectionViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, PNDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var embeddingComputeFrequency = 10
    var frameCounter = 0
    var metadata: JSON?
    var maps = [String]()
    var sphere = SCNSphere()
    private var camManager: CameraManager? = nil;
    var scenePoints: [[Double]] = [[Double]]()
    let rootNode = SCNNode()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        sceneView.delegate = self
        self.sceneView.session.delegate = self
        
        sceneView.showsStatistics = false
        
        LibPlacenote.instance.multiDelegate += self
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        if let camera: SCNNode = sceneView?.pointOfView {
            camManager = CameraManager(scene: sceneView.scene, cam: camera)
        }
        
        initMetadata(metadataCallback(_:))
        self.sceneView.scene.rootNode.addChildNode(self.rootNode)
        
        self.sphere = SCNSphere(radius: CGFloat(0.02))
        sphere.firstMaterial?.diffuse.contents = UIColor.magenta.withAlphaComponent(CGFloat(0.5))
    }

    func metadataCallback(_ _metadata: JSON) {
        self.metadata = _metadata
        
        // for each scene
        for (key, value) in self.metadata! {
            
            if key != "metauser" {
                let mapKey = value["mapKey"].stringValue
                
                print(value)
                
                if mapKey.count > 0 {
                    self.maps.append( mapKey )
                    self.scenePoints = value["modelObjects"].arrayObject as! [[Double]]
                    print(self.scenePoints)
                    
//                    if let scenePoints = value["modelObjects"].arrayObject as? [String] {
//                        self.scenePoints = stringToMatrix(scenePoints)

//                    }
                }
            }
        }
        
        if self.maps.count > 0 {
            
            print("Attempting to retrieve map: \(self.maps[0])")
            
            LibPlacenote.instance.loadMap(mapId: self.maps[0],
                                          downloadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                                            if (completed) {
                                                LibPlacenote.instance.startSession()
                                                print("Map downloaded and initialised.")
                                            }
            }
            )
        } else {
            print("No local maps available")
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.frameCounter += 1
        let image: CVPixelBuffer = frame.capturedImage
        let pose: matrix_float4x4 = frame.camera.transform
        LibPlacenote.instance.setFrame(image: image, pose: pose)
    }
    
    //Receive a pose update when a new pose is calculated
    // PlacenoteSDK
    func onPose(_ outputPose: matrix_float4x4, _ arkitPose: matrix_float4x4) -> Void {
    }
    
    //Receive a status update when the status changes
    // PlacenoteSDK
    func onStatusChange(_ prevStatus: LibPlacenote.MappingStatus, _ currStatus: LibPlacenote.MappingStatus) {
        print( prevStatus, currStatus )
        
        if prevStatus != LibPlacenote.MappingStatus.running && currStatus == LibPlacenote.MappingStatus.running {
            
            // need to first clear existing scene
            for node in self.rootNode.childNodes {
                node.removeFromParentNode()
            }
            
            print(self.scenePoints)
            
            for point in self.scenePoints {
                print(point)
                let geometry = SCNSphere(radius: CGFloat(0.02))
                geometry.firstMaterial?.diffuse.contents = UIColor.magenta
                let node = SCNNode(geometry: geometry)
            
                node.position = SCNVector3Make(Float(point[0]), Float(point[1]), Float(point[2]))
                
//                self.rootNode.addChildNode(node)
                self.sceneView.scene.rootNode.addChildNode(node)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        self.sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.automaticallyUpdatesLighting = true
        sceneView.session.run(configuration)
    }
    
}
