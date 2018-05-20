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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        sceneView.delegate = self
        self.sceneView.session.delegate = self
        
        sceneView.showsStatistics = false
        
        let scene = SCNScene()
        sceneView.scene = scene
        
//        retrieveMetadata()
        
        LibPlacenote.instance.multiDelegate += self
        
        self.metadata = initMetadata()
        
        // for each scene
        for (key, value) in self.metadata! {
            
            if key != "metauser" {
                let mapKey = value["mapKey"].stringValue
                if mapKey.count > 0 {
                    self.maps.append( mapKey )
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
        
        self.sphere = SCNSphere(radius: CGFloat(0.02))
        sphere.firstMaterial?.diffuse.contents = UIColor.magenta.withAlphaComponent(CGFloat(0.5))
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.frameCounter += 1
    }
    
    //Receive a pose update when a new pose is calculated
    // PlacenoteSDK
    func onPose(_ outputPose: matrix_float4x4, _ arkitPose: matrix_float4x4) -> Void {
        
    }
    //Receive a status update when the status changes
    // PlacenoteSDK
    func onStatusChange(_ prevStatus: LibPlacenote.MappingStatus, _ currStatus: LibPlacenote.MappingStatus) {
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        self.sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.automaticallyUpdatesLighting = true
        sceneView.session.run(configuration)
    }
    
}
