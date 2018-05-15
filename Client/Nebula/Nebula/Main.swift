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

import ARKit
import SwiftyJSON

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var sceneRecordCompletionButton: UIBarButtonItem!
    
    let recordbutton = UIButton()
    let starpathbutton = UIButton()
    let tap: UITapGestureRecognizer = UITapGestureRecognizer()
    
    var atlasSession: ARSession = ARSession()
    var vision = Vision()
    
    var trackingReady: Bool = false
    var trackingON: Bool = false
    var dataWriteStarted: Bool = false
    var dataWriteComplete: Bool = false
    var allowDataWrite: Bool = false
    var saveCurrentStarpath: Bool = true
    var isRecording: Bool = false
    var screenTapped: Bool = false
    
    var frameCounter: Int = 0
    var sessionframeCounter: Int = 0
    var computeFrequency = 4
    let markerFrequency = 10
    
    let grid: WorldGrid = WorldGrid()
    var displayimage: String = ""
    var metadata: JSON?
    var keyFrame: String = ""
    var jsonObject = [String:Any]()
    var recordStartTime: String?
    var recordKey: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        self.sceneView.session.delegate = self
        sceneView.showsStatistics = false
        let scene = SCNScene()
        sceneView.scene = scene
        
        self.addButton()
        
        self.sceneRecordCompletionButton.isEnabled = false
        self.metadata = initMetadata()
        
        tap.addTarget(self, action: #selector(screenTap) )
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func screenTap() {
        self.screenTapped = true
    }
    
    func receiveEmbedding(_ _embedding: [Double]) {
        if var _ = self.metadata {
            self.metadata![self.recordKey]["embedding"].stringValue = _embedding.description
            updateMetadata(self.metadata!)
        }
    }
    
    func writeData() {
        
        if self.frameCounter == 0 && self.trackingON == false {
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                let valid = JSONSerialization.isValidJSONObject(self.jsonObject)
                if valid {
                    
                    let json = JSON(self.jsonObject)
                    
                    let representation = dataToDictionary(json)
                    let endtime = getCurrentTime()
                    let jsonFileName = "data.json"
                    let jsonFilePath = getFilePath(fileFolder: self.recordKey, fileName: jsonFileName)
                    
                    do {
                        try representation.write(toFile: jsonFilePath, atomically: false, encoding: String.Encoding.utf8)
                        
                        if var _ = self.metadata {
                            
                            // compute embedding of keyframe and write it to metadata
                            // load image that we are going to compute the embedding of
                            let keyframepath = getFilePath(fileFolder: self.recordKey, fileName: self.keyFrame)
                            print(keyframepath  )
                            if let keyframeimage = UIImage(contentsOfFile: keyframepath) {
                                self.vision.processFrame(keyframeimage, self.receiveEmbedding)
                            }
                            
                            let datum: JSON = [
                                "starttime": self.recordStartTime!,
                                "endtime": endtime,
                                "filename": self.recordKey,
                                "dataname": jsonFileName,
                                "displayname": "Untitled",
                                "uploaded": "false",
                                "displayimage": self.displayimage,
                                "embedding": ""
                            ]
                            
                            self.metadata![self.recordKey] = datum
                            updateMetadata(self.metadata!)
                        }
                    }catch {
                    }
                }
                
                DispatchQueue.main.async {
                    self.jsonObject.removeAll()
                    self.recordStartTime = nil
                    self.sceneRecordCompletionButton.isEnabled = true
                }
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
            case .limited:
                break
            }
        }
        
        if self.trackingReady {
            
            self.sessionframeCounter += 1
            if self.sessionframeCounter % self.markerFrequency == 0 {
                
                guard let transform = self.sceneView.session.currentFrame?.camera.transform else {return}
                let position = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                
                self.grid.add("", position, isstarpath: true)
            }
            
            // show the button
            if self.recordbutton.isHidden {
                self.recordbutton.isHidden = false
                self.starpathbutton.isHidden = false
            }
            
            if self.isRecording {
                
                self.trackingON = true
                
                if self.recordStartTime == nil {
                    self.recordStartTime = getCurrentTime()
                    self.recordKey = uniqueKey()
                }
                
                DispatchQueue.global(qos: .userInteractive).async {
                    
                    if self.sessionframeCounter % self.computeFrequency == 0 {
                        self.frameCounter += 1      // we're adding a frame to the stack
                        let jsonNode = currentFrameInfoToDic(currentFrame: frame)
                        let filename = jsonNode["imagename"] as! String
                        
                        if self.screenTapped {
                            self.screenTapped = false
                            self.keyFrame = filename
                            print("\(self.keyFrame) selected as keyframe")
                        }
                        
                        self.jsonObject[filename] = jsonNode
                        
                        if self.displayimage == "" {
                            self.displayimage = filename
                        }
                        
                        let uiImage = pixelBufferToUIImage(pixelBuffer: frame.capturedImage)
                        let image = UIImageJPEGRepresentation( uiImage , 0.25)!
                        
                        let filePath = getFilePath(fileFolder: self.recordKey, fileName: filename)
                        try? image.write(to: URL(fileURLWithPath: filePath))
                        
                        self.frameCounter -= 1  // removing a frame from the stack
//                        self.writeData()
                    }
                    
                }
                
            } else if self.trackingON {
                self.trackingON = false
                print("trackingON: \(self.trackingON)")
                
                self.writeData()
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        self.sceneView.automaticallyUpdatesLighting = true
        sceneView.session.run(configuration)
    }
}

extension ViewController {
    func addButton() {
        
        let recordbuttonimg = UIImage(named: "buttonopen")
        
        let size: Int = 48
        let bx1 = CGFloat((self.sceneView.bounds.maxX/2) - 24)
        let by1 = CGFloat(self.sceneView.bounds.maxY - 80)
        
        recordbutton.frame = CGRect(x: bx1, y: by1, width: CGFloat(size), height: CGFloat(size))
        recordbutton.backgroundColor = .clear
        recordbutton.setImage(recordbuttonimg, for: .normal)
        recordbutton.addTarget(self, action: #selector(recordButtonPressed), for: .touchUpInside)
        self.sceneView.addSubview(recordbutton)
        self.recordbutton.isHidden = true
        let bx2 = CGFloat((self.sceneView.bounds.midX/2) - 24)
        let by2 = CGFloat(self.sceneView.bounds.maxY - 80)
        
        let starpathbuttonimg = UIImage(named: "starpathopen")
        starpathbutton.frame = CGRect(x: bx2, y: by2, width: CGFloat(size), height: CGFloat(size))
        starpathbutton.backgroundColor = .clear
        starpathbutton.setImage(starpathbuttonimg, for: .normal)
        starpathbutton.addTarget(self, action: #selector(starpathButtonPressed), for: .touchUpInside)
        self.sceneView.addSubview(starpathbutton)
        self.starpathbutton.isHidden = true
    }
    
    @objc func recordButtonPressed() {
        if self.isRecording {
            self.isRecording = false
            self.recordbutton.setImage(UIImage(named: "buttonopen"), for: .normal)
        } else {
            self.isRecording = true
            self.recordbutton.setImage(UIImage(named: "buttonclosed"), for: .normal)
        }
    }
    
    @objc func starpathButtonPressed() {
        if self.grid.canAdd {
            self.grid.canAdd = false
            starpathbutton.setImage(UIImage(named: "starpathopen"), for: .normal)
        } else {
            self.grid.canAdd = true
            starpathbutton.setImage(UIImage(named: "starpathclosed"), for: .normal)
        }
    }
}















// end

