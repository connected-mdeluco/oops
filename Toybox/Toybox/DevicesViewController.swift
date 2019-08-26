//
//  DevicesViewController.swift
//  
//
//  Created by cl-dev on 2019-08-23.
//

import PromiseKit
import UIKit

class DevicesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var devicesSegmentedControl: UISegmentedControl!
    @IBOutlet var devicesTableView: UITableView!

    // Category ID: Name
    let categories: [Int:String] = [
        17: "IoT (Android)", // "AAI"
        3: "Android", // "ADP"
        6: "Android", // "ADT"
        33: "Streaming Devices", // "ASD"
        10: "Music Players", // "IDM"
        4: "Apple", // "IDP"
        7: "Apple", // "IDT"
        2: "Machines", // "MMA"
        8: "IoT (Other)", // "XAI"
        34: "Cameras", // "XCA"
        16: "Headsets", // "XHS"
        12: "Speakers" // "XSP"
    ]

    // Segment: List of Category IDs
    let segments: [Int: [Int]] = [
        0: [3, 4],
        1: [6, 7],
        2: [34, 16, 10, 12, 33],
        3: [17, 8, 2]
    ]

    var devices = [[Device]]()

    override func viewDidLoad() {
        super.viewDidLoad()

        devicesTableView.delegate = self
        devicesTableView.dataSource = self

        let selectedSegmentIndex = devicesSegmentedControl.selectedSegmentIndex
        loadDevices(for: selectedSegmentIndex)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func devicesSegmentedControlChangedAction(_ sender: UISegmentedControl) {
        devices.removeAll()
        devicesTableView.reloadData()
        loadDevices(for: sender.selectedSegmentIndex)
    }
}

// MARK: - Table View

extension DevicesViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        let selectedSegment = devicesSegmentedControl.selectedSegmentIndex
        return segments[selectedSegment]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let selectedSegment = devicesSegmentedControl.selectedSegmentIndex
        guard let segmentCode = segments[selectedSegment]?[section] else { return nil }
        return categories[segmentCode]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < devices.count else { return 1 }
        return devices[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        cell.textLabel?.text = ""
        cell.detailTextLabel?.text = ""

        guard indexPath.section < devices.count else { return cell }
        let devicesForSection = devices[indexPath.section]
        let status = devicesForSection[indexPath.row].status.statusMeta
        cell.textLabel?.text = devicesForSection[indexPath.row].name
        cell.detailTextLabel?.text = status != .deployable ? "Unavailable" : "Available"

        return cell
    }
}

// MARK: - Devices

extension DevicesViewController {
    func loadDevices(for segment: Int) {
        guard let allPromises = segments[segment]?.map({ SnipeManager.getDevices(categoryId: $0) }) else { return }

        when(resolved: allPromises).done { results in
            for result in results {
                switch result {
                case .fulfilled(let deviceResults):
                    self.devices.append(deviceResults)
                case .rejected(_):
                    break
                }
            }
            self.devicesTableView.reloadData()
        }
    }
}
