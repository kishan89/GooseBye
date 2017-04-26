//
//  DJIViewController.swift
//  GooseBye
//
//  Created by Kishan Patel on 3/21/17.
//  Copyright © 2017 Kishan Patel. All rights reserved.
//

import UIKit
import DJISDK
import MapKit
import CoreLocation

class DJIViewController: DJIBaseViewController, DJISDKManagerDelegate, UIGestureRecognizerDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var progressAlertView: UIAlertController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let app_key = "f2edfb914c4369e335f3520c"

        DJISDKManager.registerApp(app_key, with: self)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        longPressGestureRecognizer.delaysTouchesBegan = true
        longPressGestureRecognizer.delegate = self
        self.mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        locationManagerSetup()
        getLocation()
        mapSetup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sdkManagerDidRegisterAppWithError(_ error: Error?) {
        guard error == nil  else {
            self.showAlertResult("Error:\(error!.localizedDescription)")
            return
        }
        
        DJISDKManager.startConnectionToProduct()
        
    }
    
    
    func sdkManagerProductDidChange(from oldProduct: DJIBaseProduct?, to newProduct: DJIBaseProduct?) {
        
        guard let newProduct = newProduct else
        {
            ConnectedProductManager.sharedInstance.connectedProduct = nil
            return
        }
        
        //Updates the product's model
        if let oldProduct = oldProduct {
        }
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            
            
            if let _ = error {
            }else{
            }
            
        }
        
        //Updates the product's connection status
        
        ConnectedProductManager.sharedInstance.connectedProduct = newProduct
        
    }
    
    @IBAction func takeoffPress() {
        let fc: DJIFlightController? = self.fetchFlightController()
        if fc != nil {
            fc!.takeoff(completion: {[weak self](error: Error?) -> Void in
                if error != nil {
                    self?.showAlertResult("Takeoff Error: \(error!.localizedDescription)")
                }
                else {
                    self?.showAlertResult("Takeoff Succeeded.")
                }
            })
        }
        else {
            self.showAlertResult("Component Not Exist")
        }
    }
    
    @IBAction func landPress() {
        let fc: DJIFlightController? = self.fetchFlightController()
        if fc != nil {
            fc!.autoLanding(completion: {[weak self](error: Error?) -> Void in
                if error != nil {
                    self?.showAlertResult("Land Error:\(error!.localizedDescription)")
                }
                else {
                    self?.showAlertResult("Land Succeeded.")
                }
            })
        }
        else {
            self.showAlertResult("Component Not Exist")
        }
    }
    
    // Waypoint Mission
    
    var missionManager: DJIMissionManager = DJIMissionManager.sharedInstance()!
    var waypointMission: DJIWaypointMission = DJIWaypointMission()
    var currentState: DJIFlightControllerCurrentState? = nil
    var aircraftLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid

    
    
    @IBOutlet weak var coordinatesLabel: UILabel!
    var waypoints = [DJIWaypoint]()
    var currentWaypoint: DJIWaypoint?
    
    @IBAction func addWaypoint() {
        if (currentWaypoint != nil) {
            waypoints.append(currentWaypoint!)
            self.coordinatesLabel.text! += "(\(currentWaypoint!.coordinate.latitude), \(currentWaypoint!.coordinate.longitude))"
        }
    }
    
    @IBAction func goPress() {
        uploadMission()
        startMission()
    }
    
    func uploadMission() {
        //if CLLocationCoordinate2DIsValid(self.aircraftLocation) {
            self.createWaypointMission()
            
            self.missionManager.prepare(self.waypointMission, withProgress:
                {[weak self] (progress: Float) -> Void in
                    
                    let message: String = "Mission Uploading:\(Int(100 * progress))%"
                    if self?.progressAlertView == nil {
                        self?.progressAlertView = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.alert)
                        self?.present((self?.progressAlertView)!, animated: true, completion: nil)
                    }
                    else {
                        self?.progressAlertView!.message = message
                    }
                    if progress == 1.0 {
                        self?.progressAlertView?.dismiss(animated: true, completion: nil)
                        self?.progressAlertView = nil
                    }
                }, withCompletion:{[weak self] (error: Error?) -> Void in
                    
                    if self?.progressAlertView != nil  {
                        self?.progressAlertView?.dismiss(animated: true, completion: nil)
                        self?.progressAlertView = nil
                    }
                    if (error != nil) {
                        self?.showAlertResult("Upload Mission Result:\(error!)")
                    }
            })
    }


    func createWaypointMission() {
        self.waypointMission.removeAllWaypoints()
        self.waypointMission.maxFlightSpeed = 6.0
        self.waypointMission.autoFlightSpeed = 4.0
        self.waypointMission.finishedAction = DJIWaypointMissionFinishedAction.goHome
        self.waypointMission.headingMode = DJIWaypointMissionHeadingMode.auto
        self.waypointMission.flightPathMode = DJIWaypointMissionFlightPathMode.normal
        self.waypointMission.exitMissionOnRCSignalLost = true
        //self.waypointMission.pointOfInterest = CLLocationCoordinate2D(latitude: , longitude: )
        self.waypointMission.gotoFirstWaypointMode = DJIWaypointMissionGotoWaypointMode.safely
        
        for waypoint in waypoints {
            waypoint.altitude = 30.0
            let stayAction: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.stay, param: 2000)
            waypoint.add(stayAction)
            waypointMission.add(waypoint)
        }
    }
    
    func startMission() {
        self.missionManager.startMissionExecution(completion: {[weak self] (error: Error?) -> Void in
            if (error != nil ) {
                self?.showAlertResult("Start Mission:\(error!)")
            }
        })
    }
    
    func missionManager(_ manager: DJIMissionManager, didFinishMissionExecution error: Error?) {
        if (error != nil) {
            self.showAlertResult("Mission Finished with error:\(error!)")
        }
        else {
            self.showAlertResult("Mission succeeded?")
        }
    }
    
    @IBAction func stopPress() {
        stopMission()
    }
        
        
    
    func stopMission() {
    self.missionManager.stopMissionExecution(completion: {[weak self] (error: Error?) -> Void in
            if (error != nil ) {
                self?.showAlertResult("Stop Mission:\(error!)")
            }
        })
        
        
    }
    
    @IBAction func clearPress() {
        waypoints.removeAll()
        coordinatesLabel.text = ""
        
        let allAnnotations = mapView.annotations
        mapView.removeAnnotations(allAnnotations)
        
    }
    
    func flightController(_ fc: DJIFlightController, didUpdateSystemState state: DJIFlightControllerCurrentState) {
        self.currentState = state
        self.aircraftLocation = state.aircraftLocation
        if CLLocationCoordinate2DIsValid(state.aircraftLocation) {
            let heading: Double = state.attitude.yaw*M_PI/180.0
            //djiMapView!.updateAircraftLocation(state.aircraftLocation, withHeading: heading)
            
        }
        if CLLocationCoordinate2DIsValid(state.homeLocation) {
            //djiMapView!.updateHomeLocation(state.homeLocation)
        }
    }
    
    
    
    
    
    
    
    //MAP
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    var locationManager: CLLocationManager!
    var myLocation: CLLocationCoordinate2D?
    var region: MKCoordinateRegion?
    
    //add waypoint
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.ended {
            let touchLocation = gestureRecognizer.location(in: mapView)
            let locationCoordinate = mapView.convert(touchLocation,toCoordinateFrom: mapView)
            print("Tapped at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
            latitudeLabel.text = "\(locationCoordinate.latitude)"
            longitudeLabel.text = "\(locationCoordinate.longitude)"
            
            let waypoint: DJIWaypoint = DJIWaypoint(coordinate: locationCoordinate)
            self.currentWaypoint = waypoint
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationCoordinate
            mapView.addAnnotation(annotation)
            
            return
        }
        if gestureRecognizer.state != UIGestureRecognizerState.began {
            return
        }
    }
    
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
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
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
    
    
    
    
}



















class DJIBaseViewController: UIViewController, DJIBaseProductDelegate, DJIProductObjectProtocol {
    
    //var connectedProduct:DJIBaseProduct?=nil
    var moduleTitle:String?=nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (moduleTitle != nil) {
            self.title = moduleTitle
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (ConnectedProductManager.sharedInstance.connectedProduct != nil) {
            ConnectedProductManager.sharedInstance.setDelegate(self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (ConnectedProductManager.sharedInstance.connectedProduct != nil &&
            ConnectedProductManager.sharedInstance.connectedProduct?.delegate === self) {
            ConnectedProductManager.sharedInstance.setDelegate(nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func product(_ product: DJIBaseProduct, connectivityChanged isConnected: Bool) {
        if isConnected {
            NSLog("\(product.model) connected. ")
            ConnectedProductManager.sharedInstance.connectedProduct = product
            ConnectedProductManager.sharedInstance.setDelegate(self)
            
        }
        else {
            NSLog("Product disconnected. ")
            ConnectedProductManager.sharedInstance.connectedProduct = nil
        }
    }
    
    func component(withKey key: String, changedFrom oldComponent: DJIBaseComponent?, to newComponent: DJIBaseComponent?) {
        //     (newComponent as? DJICamera)?.delegate = self
        if ((newComponent is DJICamera) == true && (self is DJICameraDelegate) == true) {
            (newComponent as! DJICamera).delegate = self as? DJICameraDelegate
            
        }
        if ((newComponent is DJICamera) == true && (self is DJIPlaybackDelegate) == true) {
            (newComponent as! DJICamera).playbackManager?.delegate = self as? DJIPlaybackDelegate
        }
        
        if ((newComponent is DJIFlightController) == true && (self is DJIFlightControllerDelegate) == true) {
            (newComponent as! DJIFlightController).delegate = self as? DJIFlightControllerDelegate
        }
        
        if ((newComponent is DJIBattery) == true && (self is DJIBatteryDelegate) == true) {
            (newComponent as! DJIBattery).delegate = self as? DJIBatteryDelegate
        }
        
        if ((newComponent is DJIGimbal) == true && (self is DJIGimbalDelegate) == true) {
            (newComponent as! DJIGimbal).delegate = self as? DJIGimbalDelegate
        }
        
        if ((newComponent is DJIRemoteController) == true && (self is DJIRemoteControllerDelegate) == true) {
            (newComponent as! DJIRemoteController).delegate = self as? DJIRemoteControllerDelegate
        }
        
    }
    
    
    func showAlertResult(_ info:String) {
        // create the alert
        var message:String? = info
        
        if info.hasSuffix(":nil") {
            message = info.replacingOccurrences(of: ":nil", with: " success")
        }
        
        let alert = UIAlertController(title: "Message", message: "\(message ?? "")", preferredStyle: UIAlertControllerStyle.alert)
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func fetchAircraft() -> DJIAircraft?{
        return ConnectedProductManager.sharedInstance.fetchAircraft()
    }
    
    func fetchCamera() -> DJICamera? {
        return ConnectedProductManager.sharedInstance.fetchCamera()
    }
    
    func fetchGimbal() -> DJIGimbal? {
        return ConnectedProductManager.sharedInstance.fetchGimbal()
    }
    
    func fetchFlightController() -> DJIFlightController? {
        return ConnectedProductManager.sharedInstance.fetchFlightController()
    }
    
    func fetchRemoteController() -> DJIRemoteController? {
        return ConnectedProductManager.sharedInstance.fetchRemoteController()
    }
    
    func fetchBattery() -> DJIBattery? {
        return ConnectedProductManager.sharedInstance.fetchBattery()
    }
    func fetchAirLink() -> DJIAirLink? {
        return ConnectedProductManager.sharedInstance.fetchAirLink()
    }
    func fetchHandheldController() -> DJIHandheldController?{
        return ConnectedProductManager.sharedInstance.fetchHandheldController()
    }
}

protocol DJIProductObjectProtocol {
    func fetchAircraft() -> DJIAircraft?
    func fetchCamera() -> DJICamera?
    func fetchGimbal() -> DJIGimbal?
    func fetchFlightController() -> DJIFlightController?
    func fetchRemoteController() -> DJIRemoteController?
    func fetchBattery() -> DJIBattery?
    func fetchAirLink() -> DJIAirLink?
    func fetchHandheldController() -> DJIHandheldController?
}


class ConnectedProductManager: DJIProductObjectProtocol {
    static let sharedInstance = ConnectedProductManager()
    
    var connectedProduct:DJIBaseProduct? = nil
    
    func fetchAircraft() -> DJIAircraft? {
        if (self.connectedProduct == nil) {
            return nil
        }
        if (self.connectedProduct is DJIAircraft) {
            return (self.connectedProduct as! DJIAircraft)
        }
        return nil
    }
    
    func fetchCamera() -> DJICamera? {
        if (self.connectedProduct == nil) {
            return nil
        }
        if (self.connectedProduct is DJIAircraft) {
            return (self.connectedProduct as! DJIAircraft).camera
        }
        else if (self.connectedProduct is DJIHandheld) {
            return (self.connectedProduct as! DJIHandheld).camera
        }
        
        return nil
    }
    
    func fetchGimbal() -> DJIGimbal? {
        if (self.connectedProduct == nil) {
            return nil
        }
        if (self.connectedProduct is DJIAircraft) {
            return (self.connectedProduct as! DJIAircraft).gimbal
        }
        else if (self.connectedProduct is DJIHandheld) {
            return (self.connectedProduct as! DJIHandheld).gimbal
        }
        
        return nil
    }
    
    func fetchFlightController() -> DJIFlightController? {
        if (self.connectedProduct == nil) {
            return nil
        }
        if (self.connectedProduct is DJIAircraft) {
            return (self.connectedProduct as! DJIAircraft).flightController
        }
        return nil
    }
    
    func fetchRemoteController() -> DJIRemoteController? {
        if (self.connectedProduct == nil) {
            return nil
        }
        if (self.connectedProduct is DJIAircraft) {
            return (self.connectedProduct as! DJIAircraft).remoteController
        }
        return nil
    }
    
    func fetchBattery() -> DJIBattery? {
        if (self.connectedProduct == nil) {
            return nil
        }
        if (self.connectedProduct is DJIAircraft) {
            return (self.connectedProduct as! DJIAircraft).battery
        }
        else if (self.connectedProduct is DJIHandheld) {
            return (self.connectedProduct as! DJIHandheld).battery
        }
        
        return nil
    }
    
    func fetchAirLink() -> DJIAirLink? {
        if (self.connectedProduct == nil) {
            return nil
        }
        if (self.connectedProduct is DJIAircraft) {
            return (self.connectedProduct as! DJIAircraft).airLink
        }
        else if (self.connectedProduct is DJIHandheld) {
            return (self.connectedProduct as! DJIHandheld).airLink
        }
        
        return nil
    }
    
    func fetchHandheldController() -> DJIHandheldController? {
        if (self.connectedProduct == nil) {
            return nil
        }
        if (self.connectedProduct is DJIHandheld) {
            return (self.connectedProduct as! DJIHandheld).handheldController
        }
        return nil
    }
    
    func setDelegate(_ delegate:DJIBaseProductDelegate?) {
        self.connectedProduct?.delegate = delegate
    }
    
}
