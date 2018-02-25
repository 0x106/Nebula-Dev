//
//  Util.swift
//  Nebula
//
//  Created by Guanqi Yu on 23/6/17.
//  Copyright © 2017 Guanqi Yu. All rights reserved.
//
//
//
//  Additional content by Jordan Campbell 20/02/18

import Foundation
import SceneKit
import ARKit
import SwiftyJSON

extension SCNVector3
{
    /**
     * Negates the vector described by SCNVector3 and returns
     * the result as a new SCNVector3.
     */
    func negate() -> SCNVector3 {
        return self * -1
    }
}

/**
 * Adds two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

/**
 * Increments a SCNVector3 with the value of another.
 */
func += (left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

/**
 * Subtracts two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

/**
 * Decrements a SCNVector3 with the value of another.
 */
func -= (left: inout  SCNVector3, right: SCNVector3) {
    left = left - right
}

/**
 * Multiplies two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
}

/**
 * Multiplies a SCNVector3 with another.
 */
func *= (left: inout  SCNVector3, right: SCNVector3) {
    left = left * right
}

/**
 * Multiplies the x, y and z fields of a SCNVector3 with the same scalar value and
 * returns the result as a new SCNVector3.
 */
func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar)
}

/**
 * Multiplies the x and y fields of a SCNVector3 with the same scalar value.
 */
func *= (vector: inout  SCNVector3, scalar: Float) {
    vector = vector * scalar
}

//
//  Utilities.swift
//  MyARDemo
//
//  Created by Guanqi Yu on 22/6/17.
//  Copyright © 2017 Guanqi Yu. All rights reserved.
//

extension SCNMaterial {
    static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = true) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = diffuse
        material.isDoubleSided = true
        if respondsToLighting {
            material.locksAmbientWithDiffuse = true
        } else {
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = diffuse
        }
        return material
    }
}

func createPlane(size: CGSize, contents: AnyObject) -> SCNPlane {
    let plane = SCNPlane(width: size.width, height: size.height)
    plane.materials = [SCNMaterial.material(withDiffuse: contents)]
    return plane
}

// MARK: - Get File Path to Write
func getDocumentsDirectory() -> String {
    let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    return dirPath
}

func getFilePath(fileFolder folderName: String, fileName fileName: String) -> String {
    let dirPath = getDocumentsDirectory()
    let filePath = NSURL(fileURLWithPath: dirPath).appendingPathComponent(folderName)?.path
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: filePath!) == false{
        do {
            try  fileManager.createDirectory(atPath: filePath!, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    let pathArray = [filePath!, fileName]
    return pathArray.joined(separator: "/")
}


// MARK: - Matrix Transform

func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
    return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
}

func arrayFromTransform(_ transform: matrix_float4x4) -> [[Float]] {
    var array: [[Float]] = Array(repeating: Array(repeating:Float(), count: 4), count: 4)
    array[0] = [transform.columns.0.x, transform.columns.1.x, transform.columns.2.x, transform.columns.3.x]
    array[1] = [transform.columns.0.y, transform.columns.1.y, transform.columns.2.y, transform.columns.3.y]
    array[2] = [transform.columns.0.z, transform.columns.1.z, transform.columns.2.z, transform.columns.3.z]
    array[3] = [transform.columns.0.w, transform.columns.1.w, transform.columns.2.w, transform.columns.3.w]
    return array
}

func arrayFromTransform(_ transform: matrix_float3x3) -> [[Float]] {
    var array: [[Float]] = Array(repeating: Array(repeating:Float(), count: 3), count: 3)
    array[0] = [transform.columns.0.x, transform.columns.1.x, transform.columns.2.x]
    array[1] = [transform.columns.0.y, transform.columns.1.y, transform.columns.2.y]
    array[2] = [transform.columns.0.z, transform.columns.1.z, transform.columns.2.z]
    return array
}

func dictFromVector3(_ vector: SCNVector3) -> [String: Float] {
    return ["x": vector.x, "y": vector.y, "z": vector.z]
}

func dictFromVector3(_ vector: vector_float3) -> [String: Float] {
    return ["x": vector.x, "y": vector.y, "z": vector.z]
}

func arrayFromPointCloud(_ pointCloud: ARPointCloud?) -> [[Float]] {
    var array = [[Float]]()
    if let points = pointCloud?.points {
        for featurePoint in UnsafeBufferPointer(start: points, count: points.count) {
            array.append([featurePoint.x, featurePoint.y, featurePoint.z])
        }
    }
    return array
}

// MARK: - File Name
func getCurrentTime() -> String {
    let date = Date()
    let calendar = Calendar.current
    let day = calendar.component(.day, from: date)
    let hour = calendar.component(.hour, from: date)
    let minutes = calendar.component(.minute, from: date)
    let second = calendar.component(.second, from: date)
    return String(day)+"-"+String(hour)+"-"+String(minutes)+"-"+String(second)
}

func pixelBufferToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let context = CIContext(options: nil)
    let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
    let uiImage = UIImage(cgImage: cgImage!)
    return uiImage
}



//extension code starts
// https://stackoverflow.com/a/42941966/7098234
func normalizeVector(_ iv: SCNVector3) -> SCNVector3 {
    let length = sqrt(iv.x * iv.x + iv.y * iv.y + iv.z * iv.z)
    if length == 0 {
        return SCNVector3(0.0, 0.0, 0.0)
    }
    
    return SCNVector3( iv.x / length, iv.y / length, iv.z / length)
    
}

// https://stackoverflow.com/a/42941966/7098234
extension SCNNode {
    
    func buildLineInTwoPointsWithRotation(from  startPoint: SCNVector3,
                                          to    endPoint: SCNVector3,
                                          radius: CGFloat,
                                          lengthOffset: CGFloat,
                                          color: UIColor) -> SCNNode {
        let w = SCNVector3(x: endPoint.x-startPoint.x,
                           y: endPoint.y-startPoint.y,
                           z: endPoint.z-startPoint.z)
        let l = CGFloat(sqrt(w.x * w.x + w.y * w.y + w.z * w.z))
        
        if l == 0.0 {
            // two points together.
            let sphere = SCNSphere(radius: radius)
            sphere.firstMaterial?.diffuse.contents = color
            self.geometry = sphere
            self.position = startPoint
            return self
            
        }
        
        let cyl = SCNCylinder(radius: radius, height: (l - lengthOffset))
        cyl.firstMaterial?.diffuse.contents = color
        
        self.geometry = cyl
        
        //original vector of cylinder above 0,0,0
        let ov = SCNVector3(0, l/2.0,0)
        //target vector, in new coordination
        let nv = SCNVector3((endPoint.x - startPoint.x)/2.0, (endPoint.y - startPoint.y)/2.0,
                            (endPoint.z-startPoint.z)/2.0)
        
        // axis between two vector
        let av = SCNVector3( (ov.x + nv.x)/2.0, (ov.y+nv.y)/2.0, (ov.z+nv.z)/2.0)
        
        //normalized axis vector
        let av_normalized = normalizeVector(av)
        let q0 = Float(0.0) //cos(angel/2), angle is always 180 or M_PI
        let q1 = Float(av_normalized.x) // x' * sin(angle/2)
        let q2 = Float(av_normalized.y) // y' * sin(angle/2)
        let q3 = Float(av_normalized.z) // z' * sin(angle/2)
        
        let r_m11 = q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3
        let r_m12 = 2 * q1 * q2 + 2 * q0 * q3
        let r_m13 = 2 * q1 * q3 - 2 * q0 * q2
        let r_m21 = 2 * q1 * q2 - 2 * q0 * q3
        let r_m22 = q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3
        let r_m23 = 2 * q2 * q3 + 2 * q0 * q1
        let r_m31 = 2 * q1 * q3 + 2 * q0 * q2
        let r_m32 = 2 * q2 * q3 - 2 * q0 * q1
        let r_m33 = q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3
        
        self.transform.m11 = r_m11
        self.transform.m12 = r_m12
        self.transform.m13 = r_m13
        self.transform.m14 = 0.0
        
        self.transform.m21 = r_m21
        self.transform.m22 = r_m22
        self.transform.m23 = r_m23
        self.transform.m24 = 0.0
        
        self.transform.m31 = r_m31
        self.transform.m32 = r_m32
        self.transform.m33 = r_m33
        self.transform.m34 = 0.0
        
        self.transform.m41 = (startPoint.x + endPoint.x) / 2.0
        self.transform.m42 = (startPoint.y + endPoint.y) / 2.0
        self.transform.m43 = (startPoint.z + endPoint.z) / 2.0
        self.transform.m44 = 1.0
        return self
    }
}
//func randomStringWithLength(len: Int) -> NSString {
//
//    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
//
//    let randomString : NSMutableString = NSMutableString(capacity: len)
//
//    for _ in 1...len{
//        let length = UInt32 (letters.length)
//        let rand = arc4random_uniform(length)
//        randomString.appendFormat("%C", letters.character(at: Int(rand)))
//    }
//
//    return randomString
//}



func uniqueKey() -> String {
    
    let chars : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let N: Int = 8
    var output = ""
    
    for _ in 0..<N {
        let index = Int(arc4random_uniform( UInt32(chars.count) ))
        output += String(chars[chars.index(chars.startIndex, offsetBy: index)])
    }
    
    return output
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
//        "light": currentFrame.lightEstimate?.ambientIntensity,
//        "pointcloud": [
//            "count": currentFrame.rawFeaturePoints?.points.count,
//            "points": arrayFromPointCloud(currentFrame.rawFeaturePoints)
//        ]
    ]
    
    return jsonObject
}



// end


