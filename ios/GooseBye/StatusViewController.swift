//
//  StatusViewController.swift
//  GooseBye
//
//  Created by Kishan Patel on 10/25/16.
//  Copyright © 2016 Kishan Patel. All rights reserved.
//

import UIKit
import CoreLocation
import DJISDK
import QuartzCore


class CurrentMission {
    static let currentMission = CurrentMission()
    private init() {}
    var mission: Mission?
}

// use class DJIBattery

class StatusViewController: DJIBaseViewController, DJISDKManagerDelegate, StreamDelegate {
        
    var progressAlertView: UIAlertController? = nil
    
    @IBOutlet weak var fieldImage: UIImageView!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var quad1: UIImageView!
    @IBOutlet weak var quad2: UIImageView!
    @IBOutlet weak var quad3: UIImageView!
    @IBOutlet weak var quad4: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        networkEnable()
        
        quad1.isHidden = true
        quad2.isHidden = true
        quad3.isHidden = true
        quad4.isHidden = true
        //let x = rPiQuery(code: "0000")
        
        //register app with DJI Phantom
        let app_key = "f2edfb914c4369e335f3520c"
        DJISDKManager.registerApp(app_key, with: self)
        
        
        circularBatteryView.angle = 0.0
        circularBatteryView.animate(toAngle: 180.0, duration: 1, completion: nil)
        batteryPercentage.text = "50%"
        
        // Fetch Weather Data
        loadWeather();
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(disablePress(img:)))
        disableImage.addGestureRecognizer(tapGestureRecognizer)
        
        
        Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(callRPI), userInfo: nil, repeats: true)
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        if let name = CurrentMission.currentMission.mission?.name {
            self.missionNameLabel.text = "  status of: \(name)"
        }
        print(CurrentMission.currentMission.mission?.name! ?? "")
    }
    
    @IBOutlet weak var missionNameLabel: UILabel!
    
    @IBOutlet weak var disableImage: UIImageView!
    
    @IBOutlet weak var disableLabel: UILabel!
    
    
    func disablePress(img: AnyObject) {
        self.disabled = !self.disabled
        print("disabled = \(self.disabled)")
        if (disabled) {
            disableLabel.text = "re-enable"
            disableImage.image = #imageLiteral(resourceName: "renable button")
            statusLabel.text = "disabling system"
        }
        else {
            disableLabel.text = "disable"
            disableImage.image = #imageLiteral(resourceName: "DisableButton")
        }
        land()

    }
    
    func loadWeather() {
        dataManager.weatherDataForLocation(latitude: 42.36, longitude: -71.06)
        {
            (response, error) in
            if response != nil {
                let currentWeatherJSON: NSDictionary = (response?.object(forKey: "currently") ?? "N/A") as! NSDictionary
                self.currentWeatherData.temperature = currentWeatherJSON.object(forKey: "temperature") as! Double?
                var timeSince1970 = currentWeatherJSON.object(forKey: "time") as! Double
                timeSince1970 -= 18000 //account for timezone difference
                self.currentWeatherData.time = Date(timeIntervalSince1970: timeSince1970) as Date?
                self.currentWeatherData.windSpeed = currentWeatherJSON.object(forKey: "windSpeed") as! Int?
                self.currentWeatherData.precipitationProbability = currentWeatherJSON.object(forKey: "precipProbability") as! Double?
                //print(response)
                let iconDesc: String = currentWeatherJSON.object(forKey: "icon") as! String
                let iconImage: UIImage? = UIImage(named: iconDesc)
                DispatchQueue.main.async(execute: {
                    self.currentTemp.text = "\(self.currentWeatherData.temperature!) ℉"
                    self.currentWeatherIcon.image = iconImage ?? #imageLiteral(resourceName: "default")
                })
                print(" ")
                print(self.currentWeatherData)
                print(" ")
            }
            else {
                print("no data")
            }
            
        }
        
    }
    
    private let dataManager = DataManager(baseURL: weatherAPI.authenticatedBaseURL)
    private var currentWeatherData = WeatherData()
    
    @IBOutlet weak var currentWeatherIcon: UIImageView!
    
    @IBOutlet weak var currentTemp: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBOutlet weak var batteryPercentage: UILabel!
    
    @IBOutlet weak var circularBatteryView: CircularProgress!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func callRPI() {
        registerBackgroundTask()
        
        switch UIApplication.shared.applicationState {
        case .active:
            print("active")
            let rPiResponse = rPiQuery(code: "0411")
            print("response: \(rPiResponse)")
            updateWaypoints(input: rPiResponse)
            
        case .background:
            print("background")
            //let _ = rPiQuery(code: "9999")
            let rPiResponse = rPiQuery(code: "0411")
            print("response: \(rPiResponse)")
            updateWaypoints(input: rPiResponse)
        case .inactive:
            break
        }
    }
    
    //change to take argument of inFieldSections
    func updateWaypoints(input: String) {
        //var count = 0
        var inFieldSections = [Int]()
        
        inFieldSections = input.characters.flatMap { Int(String($0)) }
        
        self.waypoints.removeAll()
        quad1.isHidden = true
        quad2.isHidden = true
        quad3.isHidden = true
        quad4.isHidden = true
        
        if (CurrentMission.currentMission.mission == nil) {
            print("no mission available")
            print("")
        }
            
        //mission is available
        else {
            //get field sections that have geese
            let fieldSectionCoordinates = calculateFieldSections(x1: CurrentMission.currentMission.mission!.x1!, y1: CurrentMission.currentMission.mission!.y1!, x2: CurrentMission.currentMission.mission!.x2!, y2: CurrentMission.currentMission.mission!.y2!)
            
            //generate waypoints
            for i in 0...3 {
                if (inFieldSections[i] == 1) {
                    let waypoint = DJIWaypoint(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(fieldSectionCoordinates[i].y), longitude: CLLocationDegrees(fieldSectionCoordinates[i].x)))
                    self.waypoints.append(waypoint)
                    switch inFieldSections[i] {
                    case 0: quad1.isHidden = false
                    case 1: quad2.isHidden = false
                    case 2: quad3.isHidden = false
                    case 3: quad4.isHidden = false
                    default:
                        break;
                    }
                }
            }
            
            //if there are geese, start a mission
            if (/*input != "0000" &&*/ !disabled && !badWeather && !currentlyActive) {
                statusLabel.text = "on a mission"
                takeoff()
                start()
                
            }
            else {
                //dock or stay docked
                print("stay docked")
                if (disabled) {
                    statusLabel.text = "disabled"
                }
                else {
                    statusLabel.text = "docked"
                }
            }
            for waypoint in waypoints {
                print(waypoint.coordinate)
            }
        }
    }
    
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
    
    var disabled: Bool = false
    
    var badWeather: Bool = false
    
    var currentlyActive: Bool = false
    
    
    func calculateFieldSections(x1: Double, y1: Double, x2: Double, y2: Double) -> [CGPoint] {
        let centerX = (x1 + x2)/2
        let centerY = (y1 + y2)/2
        
        let quad1_x = (x1 + centerX)/2
        let quad1_y = (y1 + centerY)/2
        
        let quad2_x = (centerX + x2)/2
        let quad2_y = (y1 + centerY)/2
        
        let quad3_x = (x1 + centerX)/2
        let quad3_y = (centerY + y2)/2
        
        let quad4_x = (centerX + x2)/2
        let quad4_y = (centerY + y2)/2
        
        return [CGPoint(x: quad1_x, y: quad1_y), CGPoint(x: quad2_x, y: quad2_y), CGPoint(x: quad3_x, y: quad3_y), CGPoint(x: quad4_x, y:quad4_y)]
    }
    
    
    //DJI Stuff
    
    func sdkManagerDidRegisterAppWithError(_ error: Error?) {
        guard error == nil  else {
            self.showAlertResult("Error:\(error!.localizedDescription)")
            return
        }
        
        DJISDKManager.startConnectionToProduct()
        
    }
    
    func sdkManagerProductDidChange(from oldProduct: DJIBaseProduct?, to newProduct: DJIBaseProduct?) {
        
        guard let newProduct = newProduct else {
            ConnectedProductManager.sharedInstance.connectedProduct = nil
            return
        }
        
        //Updates the product's model
        if let oldProduct = oldProduct {
        }
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            if let _ = error {
            } else {
            }
        }
        
        //Updates the product's connection status
        ConnectedProductManager.sharedInstance.connectedProduct = newProduct
    }
    
    func takeoff() {
        let fc: DJIFlightController? = self.fetchFlightController()
        if fc != nil {
            fc!.takeoff(completion: {[weak self](error: Error?) -> Void in
                if error != nil {
                    self?.showAlertResult("Takeoff Error: \(error!.localizedDescription)")
                }
                else {
                    self?.showAlertResult("Takeoff Succeeded.")
                    self?.statusLabel.text = "in flight"
                }
            })
        }
        else {
            self.showAlertResult("Component Not Exist")
        }
    }
    
    func land() {
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
    
    var waypoints = [DJIWaypoint]()
    
    func start() {
        uploadMission()
        
        self.missionManager.startMissionExecution(completion: {[weak self] (error: Error?) -> Void in
            if (error != nil ) {
                self?.showAlertResult("Start Mission:\(error!)")
            }
        })
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
    
    func missionManager(_ manager: DJIMissionManager, didFinishMissionExecution error: Error?) {
        if (error != nil) {
            self.showAlertResult("Mission Finished with error:\(error!)")
        }
        else {
            self.showAlertResult("Mission succeeded?")
            self.currentlyActive = false
        }
    }
    
    func createWaypointMission() {
        self.waypointMission.removeAllWaypoints()
        self.waypointMission.maxFlightSpeed = 6.0
        self.waypointMission.autoFlightSpeed = 4.0
        self.waypointMission.finishedAction = DJIWaypointMissionFinishedAction.goHome
        self.waypointMission.headingMode = DJIWaypointMissionHeadingMode.auto
        self.waypointMission.flightPathMode = DJIWaypointMissionFlightPathMode.normal
        self.waypointMission.exitMissionOnRCSignalLost = true
        self.waypointMission.gotoFirstWaypointMode = DJIWaypointMissionGotoWaypointMode.safely
        
        for waypoint in waypoints {
            waypoint.altitude = 5.0
            let stayAction: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.stay, param: 500)
            waypoint.add(stayAction)
            waypointMission.add(waypoint)
        }
    }
    
    //rPi server connection 
    
    let addr = "128.197.180.213"
    //let addr = "168.122.148.231"
    //let addr = "192.168.1.2"
    let port = 9876
    
    var inStream: InputStream?
    var outStream: OutputStream?
    var buffer = [UInt8](repeating: 0, count: 200)
    
    func networkEnable() {
        print("Network Enable")
        Stream.getStreamsToHost(withName: addr, port: port, inputStream: &inStream, outputStream: &outStream)
        
        inStream?.delegate = self
        outStream?.delegate = self
        
        //inStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        //outStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        inStream?.open()
        outStream?.open()
        
        buffer = [UInt8](repeating: 0, count: 200)
    }
    
    func rPiQuery(code: String) -> String {
        
        let data : Data = code.data(using: String.Encoding.utf8)!
        //outStream?.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
        let _ = data.withUnsafeBytes { outStream?.write($0, maxLength: data.count) }
        
        let bufferSize = 4
        var buffer = Array<UInt8>(repeating: 0, count: bufferSize)
        if (inStream?.hasBytesAvailable)! {
            let bytesRead = inStream?.read(&buffer, maxLength: bufferSize)
            if bytesRead! >= 0 {
                let output = NSString(bytes: &buffer, length: bytesRead!, encoding: String.Encoding.utf8.rawValue)
                networkEnable()
                return output as! String
            } else {
                networkEnable()
                return "EROR" //error
            }
            
        }
        else {
            print("no bytes available")
            networkEnable()
            return "EROR"
        }
    }
}


