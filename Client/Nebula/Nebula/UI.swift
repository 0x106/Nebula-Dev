//
//  UI.swift
//  Nebula
//
//  Created by Jordan Campbell on 15/05/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import ARKit

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
        
        // TEXT PARENT NODE
        let textNodeParent = SCNNode()
        textNodeParent.name = self.label
        textNodeParent.addChildNode(textNode)
        textNodeParent.addChildNode(sphereNode)
        //        textNodeParent.constraints = [billboardConstraint]
        
        self.rootNode = textNodeParent
    }
    
    init() {
        
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
