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
    
    var server: String = "http://2a11f6ee.ngrok.io"

    init() {
        
        manager = SocketManager(socketURL: URL(string: self.server)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
        }
        
        socket.on("nebula") {[unowned self] response, ack in
//            guard let data = response[0] as? String else { return }
//            ack.with("config recvd", "")
            print(response)
        }
        
        socket.connect()
    }
    
    func sendData(_ data: String) {
        print("Sending message: \(data)")
        socket.emit("data", data)
    }
    
    func sendImage(_ image: Data) {
        socket.emit("image", image)
    }
    
}
