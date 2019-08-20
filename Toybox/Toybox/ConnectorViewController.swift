//
//  ConnectorTableViewController.swift
//  Toybox
//
//  Created by cl-dev on 2019-08-15.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import PromiseKit
import UIKit

class ConnectorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    private var sortedConnectorKeys = [String]()
    var connectors = [String:[Employee]]() {
        didSet {
            sortedConnectorKeys = connectors.keys.sorted()
        }
    }

    var employee: Employee? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        view.bringSubviewToFront(activityIndicator)
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()

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
                self.activityIndicator.stopAnimating()
        }.catch({ error in
            self.connectors.removeAll()
        })
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return connectors.keys.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let keyIndex = connectors.keys.index(of: sortedConnectorKeys[section])
        return connectors[keyIndex!].value.count
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sortedConnectorKeys
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedConnectorKeys[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConnectorCell", for: indexPath)

        let employee = employeeObject(forRowAt: indexPath)
        cell.textLabel?.text = employee.name

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        employee = employeeObject(forRowAt: indexPath)

        let alertController = UIAlertController(title: "Choose Employee", message: "Checkout as \(employee!.name)?", preferredStyle: .alert)
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.performSegue(withIdentifier: "SelectedConnectorUnwindSegue", sender: self)
        })

        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        alertController.popoverPresentationController?.sourceView = self.view
        present(alertController, animated: true, completion: nil)
    }

    func characterString(fromString string: String, atPosition position: Int) -> String {
        let index = string.index(string.startIndex, offsetBy: position)
        return String(string[index])
    }

    func employeeObject(forRowAt indexPath: IndexPath) -> Employee {
        let keyIndex = connectors.keys.index(of: sortedConnectorKeys[indexPath.section])
        let employees = connectors[keyIndex!].value
        return employees[indexPath.row]
    }
}
