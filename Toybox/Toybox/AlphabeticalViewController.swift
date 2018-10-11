//
//  AlphabeticalViewController.swift
//  Toybox
//
//  Created by cl-dev on 2018-09-12.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit
import PromiseKit

class AlphabeticalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // TODO: cache employee list and dictionaryEmployees?
    // or just employees and create dictionary upon
    // reload?
    
    @IBOutlet weak var searchBar: UISearchBar!
     var searchActive : Bool = false
    @IBOutlet weak var tableView: UITableView!
    
    var dictionaryEmployees = [String:[Employee]]()
    var filteredDictionaryEmployees = [String:[Employee]]()
    var employees = [Employee]()
    let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.barTintColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)

        navigationController?.navigationBar.tintColor = UIColor.black
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        let spinner = self.displayLoadingSpinner()
        
        let promise = SnipeManager.getUserList()
        promise.done { (response) in
            self.employees = response as [Employee]
            self.createDictionary(from: self.employees)
            self.removeLoadingSpinner(spinner)
            self.tableView.reloadData()
            }.catch { (error) in
                self.removeLoadingSpinner(spinner)
                print("Error received when fetching users: \(error)")
                let snipeError = error as! ErrorManager.SnipeError
                ErrorManager.handleError(ofType: snipeError, withDeviceId: nil
                    , fromInstance: self)
        }
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let index = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueDestination = segue.destination as? QRScannerController
        segueDestination?.setScanType(as: QRScannerController.ScanType.borrowDevice)
        
        let employeeCell = sender as? EmployeeTableViewCell
        if let employeeCell = employeeCell {
            segueDestination?.setEmployee(as: employeeCell.employee)
        }
    }
    
    func createDictionary(from employees: [Employee]) {
        employees.forEach { employee in
            let firstLetter = String(employee.name.prefix(1))
            var curList = dictionaryEmployees[firstLetter]
            if var unwrappedCurList = curList {
                unwrappedCurList.append(employee)
                curList = unwrappedCurList
            } else {
                curList = [employee]
            }
            dictionaryEmployees.updateValue(curList!, forKey: firstLetter)
        }
    }
}

// MARK: -TableView

extension AlphabeticalViewController {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tmp = searchActive ? filteredDictionaryEmployees[letters[indexPath.section]] : dictionaryEmployees[letters[indexPath.section]]
        
        let newEmployeeCell = tableView.dequeueReusableCell(withIdentifier: EmployeeTableViewCell.identifier, for: indexPath) as? EmployeeTableViewCell
        
        if let unwrappedEmployee = tmp?[indexPath.row] {
            newEmployeeCell?.configureWithItem(item: unwrappedEmployee)
        }
        
        if let newEmployeeCell = newEmployeeCell {
            return newEmployeeCell
        } else {
            return EmployeeTableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let employeesInSection = searchActive ? filteredDictionaryEmployees[letters[section]] : dictionaryEmployees[letters[section]]
        if let employeesInSection = employeesInSection {
            return employeesInSection.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("hey u selected a cell")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return letters.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return letters
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.tableView(self.tableView, numberOfRowsInSection: section) > 0 {
            return letters[section]
        } else {
            return nil
        }
    }
}

// MARK: -Searchbar

extension AlphabeticalViewController: UISearchBarDelegate {
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
        setSearchActiveOnKeyboardDismiss()
        tableView.reloadData()
    }
    
    func setSearchActiveOnKeyboardDismiss() {
        if searchBar.text?.count != 0 {
            searchActive = true
        } else {
            searchActive = false
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
        if searchBar.text?.count != 0 {
            tableView.reloadData()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        setSearchActiveOnKeyboardDismiss()
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var isSearchEmpty = true
            dictionaryEmployees.forEach { (key, value) in
                filteredDictionaryEmployees[key] = value.filter({ (employee) -> Bool in
                    let tmp: NSString = employee.name as NSString
                    let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
                    isSearchEmpty = range.location != NSNotFound
                    return isSearchEmpty
                })
            }
            searchActive = !isSearchEmpty
        
        self.tableView.reloadData()
    }
}

// MARK: -Spinner

extension AlphabeticalViewController {
    func displayLoadingSpinner() -> UIView {
        let spinnerView = UIView.init(frame: self.view.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            self.view.addSubview(spinnerView)
        }
        
        return spinnerView
    }
    
    func removeLoadingSpinner(_ spinner: UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}
