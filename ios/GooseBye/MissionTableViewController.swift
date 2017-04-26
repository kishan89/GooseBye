//
//  MissionTableViewController.swift
//  GooseBye
//
//  Created by Kishan Patel on 11/12/16.
//  Copyright © 2016 Kishan Patel. All rights reserved.
//

import UIKit

class MissionTableViewController: UITableViewController {
    
    var missions = [Mission]()
    
    override func viewDidLoad() {
        //missions.removeAll()
        super.viewDidLoad()
        
        if let savedMissions = loadMissions() {
            missions += savedMissions
        }
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    func saveMissions() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(missions, toFile: Mission.ArchiveURL.path)
        if !isSuccessfulSave {
            print("Failed to save missions...")
        }
    }
    
    func loadMissions() -> [Mission]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Mission.ArchiveURL.path) as? [Mission]
    }
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true);
        
        if editing {
            addButton.isEnabled = false
        }
        else {
            addButton.isEnabled = true
            saveMissions()
        }
    }
    
    //let addr = "168.122.148.231"
    //i think commenting these out won't matter
    let addr = "128.197.180.210"
    let port = 9876
    var inStream: InputStream?
    var outStream: OutputStream?
    
    var buffer = [UInt8](repeating: 0, count: 200)
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let missionDetailViewController = segue.destination as! NewMissionViewController
            // Get the cell that generated this segue.
            if let selectedMissionCell = sender as? MissionTableViewCell {
                let indexPath = tableView.indexPath(for: selectedMissionCell)!
                let selectedMission = missions[indexPath.row]
                missionDetailViewController.mission = selectedMission
            }
        }
        else if segue.identifier == "AddItem" {
            print("Adding new mission")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return missions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MissionTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! MissionTableViewCell
        
        let mission = missions[indexPath.row]
        cell.nameLabel.text = mission.name
        
        return cell
    }
    
    @IBAction func unwindToMissionList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? NewMissionViewController, let mission = sourceViewController.mission {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing meal.
                missions[selectedIndexPath.row] = mission
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                let newIndexPath = IndexPath(row: missions.count, section: 0)
            missions.append(mission)
            tableView.insertRows(at: [newIndexPath], with: .bottom) 
            }
            saveMissions()
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            missions.remove(at: indexPath.row)
            saveMissions()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
