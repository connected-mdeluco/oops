//
//  ConnectorTableViewController.swift
//  Toybox
//
//  Created by cl-dev on 2019-08-15.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import PromiseKit
import UIKit

class ConnectorTableViewController: UITableViewController {

    private var sortedConnectorKeys = [String]()
    var connectors = [String:[Employee]]() {
        didSet {
            sortedConnectorKeys = connectors.keys.sorted()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        firstly {
            SnipeManager.getUserList()
            }.done { result in
                guard result.count > 0 else { return }
                let employees = result as [Employee]
                self.connectors = employees.reduce(into: [String:[Employee]](), { d, employee in
                    let firstLetter = self.characterString(fromString: employee.name, atPosition: 0)
                    if (!d.keys.contains(firstLetter)) {
                        d[firstLetter] = [Employee]()
                    }
                    d[firstLetter]?.append(employee)
                })
                self.tableView.reloadData()
        }.catch({ error in
            self.connectors.removeAll()
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return connectors.keys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let keyIndex = connectors.keys.index(of: sortedConnectorKeys[section])
        return connectors[keyIndex!].value.count
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sortedConnectorKeys
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedConnectorKeys[section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConnectorCell", for: indexPath)

        let keyIndex = connectors.keys.index(of: sortedConnectorKeys[indexPath.section])
        let employees = connectors[keyIndex!].value
        let employee = employees[indexPath.row]

        cell.textLabel?.text = employee.name

        return cell
    }

    func characterString(fromString string: String, atPosition position: Int) -> String {
        let index = string.index(string.startIndex, offsetBy: position)
        return String(string[index])
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
