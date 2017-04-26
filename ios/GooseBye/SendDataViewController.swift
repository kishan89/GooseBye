//
//  SendDataViewController.swift
//  GooseBye
//
//  Created by Kishan Patel on 2/2/17.
//  Copyright © 2017 Kishan Patel. All rights reserved.
//

import UIKit

class SendDataViewController: UIViewController, StreamDelegate {
    
    @IBOutlet weak var buttonConnect: UIButton!
    
    @IBOutlet weak var buttonSendMsg: UIButton!
    
    @IBOutlet weak var buttonQuit: UIButton!
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var labelConnection: UILabel!
    
    
    let addr = "128.197.180.188"
    let port = 9876
    
    var inStream: InputStream?
    var outStream: OutputStream?
    
    var buffer = [UInt8](repeating: 0, count: 200)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        buttonConnect.addTarget(self, action: #selector(btnConnectPressed), for: UIControlEvents.touchUpInside)
        buttonSendMsg.addTarget(self, action: #selector(btnSendMsgPressed), for: UIControlEvents.touchUpInside)
        buttonQuit.addTarget(self, action: #selector(btnQuitPressed), for: UIControlEvents.touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func btnConnectPressed(sender: UIButton) {
        NetworkEnable()
        print("network enabled")
        buttonConnect.isEnabled = false
        
    }
    
    func btnSendMsgPressed(sender: UIButton) {
        let data : Data = "hello. This is IPHONE ".data(using: String.Encoding.utf8)!
        //outStream?.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
        let bytesWritten = data.withUnsafeBytes { outStream?.write($0, maxLength: data.count) }
        print(bytesWritten ?? "nil")
    }
    
    func btnQuitPressed(sender: UIButton) {
        let data : Data = "Quit".data(using: String.Encoding.utf8)!
        //outStream?.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
        let bytesWritten = data.withUnsafeBytes { outStream?.write($0, maxLength: data.count) }
        print(bytesWritten ?? "nil")
    }
    
    func NetworkEnable() {
        print("Network Enable")
        Stream.getStreamsToHost(withName: addr, port: port, inputStream: &inStream, outputStream: &outStream)
        
        inStream?.delegate = self
        outStream?.delegate = self
        
        inStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        outStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        inStream?.open()
        outStream?.open()
        
        buffer = [UInt8](repeating: 0, count: 200)
        
        print("conn established")
    }
    
    func stream(aStream: Stream, handleEvent eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.endEncountered:
            print("EndEncountered")
            //labelConnection.text = "Connection stopped by server"
            inStream?.close()
            inStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            outStream?.close()
            print("Stop outStream currentRunLoop")
            outStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            //buttonConnect.isEnabled = true
        
        case Stream.Event.errorOccurred:
            print("error occured")
            inStream?.close()
            inStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            outStream?.close()
            outStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            //labelConnection.text = "Failed to connect to server"
            //label.text = ""
            
        case Stream.Event.hasBytesAvailable:
            print("has bytes available")
            if aStream == inStream {
                inStream!.read(&buffer, maxLength: buffer.count)
                let bufferStr = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
                //label.text = bufferStr! as String
                print(bufferStr!)
            }
            
        case Stream.Event.hasSpaceAvailable:
            print("HasSpaceAvailable")
        case Stream.Event.openCompleted:
            print("OpenCompleted")
            //labelConnection.text = "Connected to server"
        default:
            print("Unknown")
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
