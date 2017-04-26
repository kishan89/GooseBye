//
//  NewMissionViewController.swift
//  GooseBye
//
//  Created by Kishan Patel on 11/12/16.
//  Copyright © 2016 Kishan Patel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Foundation

class NewMissionViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, MKMapViewDelegate, StreamDelegate {
    
    // MARK: - Variables
    
    
    var mission: Mission?
    var locationManager: CLLocationManager!
    var myLocation: CLLocationCoordinate2D?
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var sensitivityTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var region: MKCoordinateRegion?
    @IBOutlet weak var rect: UIView!
    var mapAngle: Double?
    
    var inStream: InputStream?
    var outStream: OutputStream?
    var buffer = [UInt8](repeating: 0, count: 200)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        networkEnable()
        
        self.mapView.isPitchEnabled = true;



        // Do any additional setup after loading the view.
        
        //mapView.addSubview(rect)
        //self.mapView.bringSubview(toFront: self.rect)
        
        nameTextField.delegate = self
        sensitivityTextField.delegate = self
        
        if let mission = mission {
            navigationItem.title = mission.name
            nameTextField.text = mission.name
            sensitivityTextField.text = mission.sensitivity
            let center = CLLocationCoordinate2D(latitude: mission.latitude!, longitude: mission.longitude!)
            let span = MKCoordinateSpan(latitudeDelta: mission.deltaLatitude!, longitudeDelta: mission.deltaLongitude!)
            self.region = MKCoordinateRegion(center: center, span: span)
            self.mapAngle = mission.angle
            print(mission.angle)
            self.rect.frame = mission.rect!
            //set map to show region
        }
        checkValidMissionName()
        
        locationManagerSetup()
        getLocation()
        mapSetup()
        setConstraints()

    }
    
    let addr = "168.122.148.231"
    let port = 9876
    
    func networkEnable() {
        print("Network Enable")
        Stream.getStreamsToHost(withName: addr, port: port, inputStream: &inStream, outputStream: &outStream)
        
        inStream?.delegate = self
        outStream?.delegate = self
        
        inStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        outStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        inStream?.open()
        outStream?.open()
        
        buffer = [UInt8](repeating: 0, count: 200)
    }

    // BACKGROUND TASKS
    
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
    
    
    func getFieldRegions() {
        registerBackgroundTask()
        
        switch UIApplication.shared.applicationState {
        case .active:
            print("active")
            
            let data : Data = "0110".data(using: String.Encoding.utf8)!
            //outStream?.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
            let bytesWritten = data.withUnsafeBytes { outStream?.write($0, maxLength: data.count) }
            print(bytesWritten)
            
            
            let bufferSize = 4
            var buffer = Array<UInt8>(repeating: 0, count: bufferSize)
            
            let bytesRead = inStream?.read(&buffer, maxLength: bufferSize)
            if bytesRead! >= 0 {
                var output = NSString(bytes: &buffer, length: bytesRead!, encoding: String.Encoding.utf8.rawValue)
                print(output)
            } else {
                break
            }

        case .background:
            print("Background time remaining = \(UIApplication.shared.backgroundTimeRemaining) seconds")
            let data : Data = "0411".data(using: String.Encoding.utf8)!
            //outStream?.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
            let bytesWritten = data.withUnsafeBytes { outStream?.write($0, maxLength: data.count) }
            print(bytesWritten)
            
            
            let bufferSize = 4
            var buffer = Array<UInt8>(repeating: 0, count: bufferSize)
            
            let bytesRead = inStream?.read(&buffer, maxLength: bufferSize)
            if bytesRead! >= 0 {
                var output = NSString(bytes: &buffer, length: bytesRead!, encoding: String.Encoding.utf8.rawValue)
                print(output)
            } else {
                break
            }

        case .inactive:
            break
        }
    }
    
    @IBAction func sendMissionPress() {

        saveMission()
        CurrentMission.currentMission.mission = self.mission!
        
        print("lets send that mission")
        print(CurrentMission.currentMission.mission!.name!)
    }
    
    
    
    func stream(aStream: Stream, handleEvent eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            print("has bytes available")
            if aStream == inStream {
                inStream!.read(&buffer, maxLength: buffer.count)
                let bufferStr = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
                print(bufferStr!)
            }
        case Stream.Event.openCompleted:
            print("OpenCompleted")
        default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        mapView.showsUserLocation = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    @IBAction func cancelPress(_ sender: UIBarButtonItem) {
        let isPresentingInAddMissionMode = presentingViewController is UINavigationController
        if isPresentingInAddMissionMode {
            dismiss(animated: true, completion: nil)
        }
        else {
            _ = navigationController?.popViewController(animated: true)
            dismiss(animated: true, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        checkValidMissionName()
        let text = nameTextField.text ?? ""
        if !text.isEmpty {
            navigationItem.title = nameTextField.text
        }
        else {
            navigationItem.title = "New Mission"
        }
    }
    
    func checkValidMissionName() {
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    // MARK: - Field Area
    
    @IBAction func scaleRect(_ sender: UIPinchGestureRecognizer) {
        self.rect.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
        //sender.scale = 1
    }
    
    func setConstraints() {
        //self.rect.translatesAutoresizingMaskIntoConstraints = false
        let rectMinHeightConstraint = NSLayoutConstraint(item: self.rect, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 75)
        let rectMaxHeightConstraint = NSLayoutConstraint(item: self.rect, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 300)
        let rectMinWidthConstraint = NSLayoutConstraint(item: self.rect, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 75)
        let rectMaxWidthConstraint = NSLayoutConstraint(item: self.rect, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 300)
        self.rect.addConstraints([rectMinHeightConstraint, rectMaxHeightConstraint, rectMinWidthConstraint, rectMaxWidthConstraint])
    }
    
    // MARK: - Map
    
    func locationManagerSetup() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
        }
    }
    
    func mapSetup() {
        if let coor = mapView.userLocation.location?.coordinate{
            mapView.setCenter(coor, animated: true)
        }
        mapView.delegate = self
        mapView.mapType = MKMapType.hybrid
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.camera.heading = self.mapAngle ?? 0
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = locationManager.location!.coordinate
        
        centerMap(center: locValue)
    }
    
    func centerMap(center: CLLocationCoordinate2D) {
        self.saveCurrentLocation(center: center)
        
        let spanX = 0.007
        let spanY = 0.007
        
        let newRegion = MKCoordinateRegion(center:center , span: MKCoordinateSpanMake(spanX, spanY))
        if (self.region != nil) {
            mapView.setRegion(region!, animated: true)
        }
        else {
            mapView.setRegion(newRegion, animated: true)
        }
    }
    
    func saveCurrentLocation(center: CLLocationCoordinate2D){
        myLocation = center
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if saveButton === sender as AnyObject {
            saveMission()
        }
    }
    
    func saveMission() {
        let name = nameTextField.text ?? ""
        let sensitivity = sensitivityTextField.text
        let missionRect = self.rect.frame
        
        let missionRegion = mapView.convert(self.mapView.frame, toRegionFrom: self.view)
        let latitude = missionRegion.center.latitude
        let longitude = missionRegion.center.longitude
        let deltaLatitude = missionRegion.span.latitudeDelta
        let deltaLongitude = missionRegion.span.longitudeDelta
        
        let x1 = mapView.convert(missionRect.origin, toCoordinateFrom: self.view).longitude
        let y1 = mapView.convert(missionRect.origin, toCoordinateFrom: self.view).latitude
        
        let x2 = mapView.convert(CGPoint(x: missionRect.origin.x + missionRect.width, y: missionRect.origin.y + missionRect.height), toCoordinateFrom: self.view).longitude
        let y2 = mapView.convert(CGPoint(x: missionRect.origin.x + missionRect.width, y: missionRect.origin.y + missionRect.height), toCoordinateFrom: self.view).latitude

        print("x1, y1, x2, y2")
        print(x1)
        print(y1)
        print(x2)
        print(y2)
        
        let currentAngle = self.mapView.camera.heading
        
        print("angle: \(mapAngle)")
        print("name: \(name)")
        print("sensitivity: \(sensitivity)")
        print("region: \(mapView.convert(self.rect.frame, toRegionFrom: self.view))")
        
        mission = Mission(name: name, sensitivity: sensitivity, rect: missionRect, latitude: latitude, longitude: longitude, deltaLatitude: deltaLatitude, deltaLongitude: deltaLongitude, x1: x1, y1: y1, x2: x2, y2: y2, angle: currentAngle)

    }
}
