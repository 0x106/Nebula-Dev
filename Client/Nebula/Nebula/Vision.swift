//
//  Vision.swift
//  Nebula
//
//  Created by Jordan Campbell on 1/03/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import Foundation
import CoreML
import Vision
import ARKit

class Vision {
    
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    
    var embedding = [Double]()
    let M = 128
    
    var requestCompletionHandler: (([Double]) -> ())?
    
    init() {
        
        for _ in 0 ... self.M - 1 {
            self.embedding.append(0.0)
        }
        
        guard let predictor = try? VNCoreMLModel(for: predict().model) else {
            fatalError("Could not load model.")
        }
        
        let visionEstimationRequest = VNCoreMLRequest(model: predictor, completionHandler: self.visionEstimationCompleteHandler)
        visionEstimationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [visionEstimationRequest]
        
        print("Vision module initialised.")
    }
    
    func resizeImage(image: UIImage, newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.width) )
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    // receives a frame from the main session and sends it off as a vision request
    func processFrame(_ _image: UIImage, _ _requestCompletion: @escaping ([Double]) -> ()) {
        
        self.requestCompletionHandler = _requestCompletion
        
//        dispatchQueueML.async {
        DispatchQueue.global(qos: .userInteractive).async {
        
            let image = self.resizeImage(image: _image, newSize: CGSize(width: CGFloat(256), height: CGFloat(256)))
            
            let ciImage = CIImage(cgImage: image.cgImage!)
            let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation.right, options: [:])
            
            do {
                try imageRequestHandler.perform(self.visionRequests)
            } catch {
                return
            }
        }
    }
    
    // every time a request is made it comes through here
    func visionEstimationCompleteHandler(_ request: VNRequest, _ error: Error?) {
        
        if error != nil {
            return
        }
        
        DispatchQueue.main.async {
            guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
                return
            }
            
            let raw_embedding = observations[0].featureValue.multiArrayValue!
            self.extractEmbedding(raw_embedding)
            
            if let handler = self.requestCompletionHandler {
                handler(self.embedding)
            }
            
        }
    }
    
    func extractEmbedding(_ raw: MLMultiArray) {
        for index in 0 ... self.M-1 {
            // 'truncating' is a compiler suggestion - unsure of its usage.
            self.embedding[index] = Double( truncating: raw[index] )
        }
    }
    
    func euclideanDistance(_ this: [Double], _ that: [Double]) -> Double {
        var output = 0.0,
              diff = 0.0,
                sq = 0.0
        
        for idx in 0 ... this.count-1 {
            diff = (this[idx] - that[idx])
            sq = diff * diff
            output = output + sq
        }
        
        output = sqrt(output)
        
        return output
    }
    
}
