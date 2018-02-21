//
//  Nebula.swift
//  Nebula
//
//  Created by Jordan Campbell on 20/02/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import Foundation
import ARKit
import SocketIO

class Nebula {
    
    var manager: SocketManager
    var socket: SocketIOClient
    
    var server: String = "http://ea1f0423.ngrok.io"
    var socketID: String = ""

    init() {
        
        manager = SocketManager(socketURL: URL(string: self.server)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.socket.emit("ios-client", "nebula-ios-client")
        }
        
        // connection information from the server
        socket.on("nebula") {[unowned self] response, ack in
            guard let data = response[0] as? String else { return }
            self.socketID = data
            print("socketID: \(self.socketID)")
        }
        
        socket.connect()
    
    }
    
    func sendData(_ data: String) {
//        print("Sending message: \(data)")
        socket.emit("data", data)
    }
    
    func sendImage(_ image: [String: String]) {
//        print("Sending image: \(image["imagename"])")
        socket.emit("image", image)
    }
    
}
