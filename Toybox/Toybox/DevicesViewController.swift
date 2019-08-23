//
//  DevicesViewController.swift
//  
//
//  Created by cl-dev on 2019-08-23.
//

import UIKit

class DevicesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var devicesSegmentedControl: UISegmentedControl!
    @IBOutlet var devicesTableView: UITableView!

    let categories: [String:String] = [
        "AAI": "Android IoT",
        "ADP": "Android",
        "ADT": "Android",
        "ASD": "Streaming Devices",
        "IDM": "Music Players",
        "IDP": "Apple",
        "IDT": "Apple",
        "MMA": "Machines",
        "XAI": "Other IoT",
        "XCA": "Cameras",
        "XHS": "Headsets",
        "XSP": "Speakers"
    ]

    let segments: [Int: [String]] = [
        0: ["IDP", "ADP"],
        1: ["IDT", "ADT"],
        2: ["XSP", "ASD", "XHS", "IDM", "XCA"],
        3: ["MMA", "AAI", "XAI"]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        devicesTableView.delegate = self
        devicesTableView.dataSource = self

        // Do any additional setup after loading the view.
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
        switch sender.selectedSegmentIndex {
        case 0:
            break
        case 1:
            break
        case 2:
            break
        case 3:
            break
        default:
            break
        }
        devicesTableView.reloadData()
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
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        return cell
    }
}
