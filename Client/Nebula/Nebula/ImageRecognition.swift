//
//  ImageRecognition.swift
//  Nebula
//
//  Created by Jordan Campbell on 15/05/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import ARKit
import SwiftyJSON

class DetectionViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var embeddingComputeFrequency = 10
    var frameCounter = 0
    var vision = Vision()
    var metadata: JSON?
    var referenceEmbedding = [Double]()
    var embedList = [[Double]]()
    var sphere = SCNSphere()
    let distanceThreshold: Double = 4.0//7.5
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        sceneView.delegate = self
        self.sceneView.session.delegate = self
        
        sceneView.showsStatistics = false
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        retrieveMetadata()
                
        self.metadata = initMetadata()
        for item in self.metadata! {
            
            let _embedding = stringToArray(item.1["embedding"].stringValue)
            
            if _embedding.count > 0 {
                self.referenceEmbedding = _embedding
                self.embedList.append(_embedding)
                let _position = stringToArray(item.1["keyPosition"].stringValue)
                let _rotation = stringToArray(item.1["keyRotation"].stringValue)
            }
        }
        
        print(self.embedList.count)
        
        self.sphere = SCNSphere(radius: CGFloat(0.02))
        sphere.firstMaterial?.diffuse.contents = UIColor.magenta.withAlphaComponent(CGFloat(0.5))
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.frameCounter += 1
        if self.frameCounter % self.embeddingComputeFrequency == 0 {
            let image = pixelBufferToUIImage(pixelBuffer: frame.capturedImage)
            self.vision.processFrame(image, self.receiveEmbedding)
        }
    }
    
    func receiveEmbedding(_ _embedding: [Double]) {
        if self.referenceEmbedding.count == _embedding.count {
            
            for query_embedding in self.embedList {
                
                let distance = vision.euclideanDistance(_embedding, query_embedding)
                print(distance)
                if distance < self.distanceThreshold {
                    let center = self.sceneView.center
                    if let hit = self.sceneView.hitTest(center, types: ARHitTestResult.ResultType.featurePoint).first {
                        let node = SCNNode(geometry: self.sphere)
                        node.position = SCNVector3Make(hit.worldTransform.columns.3.x,
                                                       hit.worldTransform.columns.3.y,
                                                       hit.worldTransform.columns.3.z)
                        self.sceneView.scene.rootNode.addChildNode(node)
                    }
                }
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
