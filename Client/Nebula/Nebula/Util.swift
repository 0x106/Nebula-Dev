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

func getFilePath(fileFolder folderName:String, fileName fileName: String) -> String {
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


