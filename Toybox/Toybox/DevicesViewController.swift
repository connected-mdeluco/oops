//
//  DevicesViewController.swift
//  Toybox
//
//  Created by cl-dev on 2018-09-12.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit
import PromiseKit

class DevicesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // TODO: cache device list and dictionaryDevices?
    // or just devices and create dictionary upon
    // reload?

    @IBOutlet weak var searchBar: UISearchBar!
    var searchActive : Bool = false
    @IBOutlet weak var tableView: UITableView!

    var dictionaryDevices = [String:[Device]]()
    var filteredDictionaryDevices = [String:[Device]]()
    var devices = [Device]()
    let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.barTintColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)

        navigationController?.navigationBar.tintColor = UIColor.black
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

        let spinner = self.displayLoadingSpinner()

        let promise = SnipeManager.getDevices()
        promise.done { (response) in
            self.devices = response as [Device]
            self.createDictionary(from: self.devices)
            self.removeLoadingSpinner(spinner)
            self.tableView.reloadData()
            }.catch { (error) in
                self.removeLoadingSpinner(spinner)
                print("Error received when fetching devices: \(error)")
                let snipeError = error as! ErrorManager.SnipeError
                ErrorManager.handleError(ofType: snipeError, withDevice: nil
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

    func createDictionary(from devices: [Device]) {
        devices.forEach { device in
            let firstLetter = String(device.indexString.prefix(1)).uppercased()
            var curList = dictionaryDevices[firstLetter]
            if var unwrappedCurList = curList {
                unwrappedCurList.append(device)
                curList = unwrappedCurList
            } else {
                curList = [device]
            }
            dictionaryDevices.updateValue(curList!, forKey: firstLetter)
        }
    }
}

// MARK: -TableView

extension DevicesViewController {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tmp = searchActive ? filteredDictionaryDevices[letters[indexPath.section]] : dictionaryDevices[letters[indexPath.section]]

        let newDeviceCell = tableView.dequeueReusableCell(withIdentifier: DeviceTableViewCell.identifier, for: indexPath) as? DeviceTableViewCell

        if let unwrappedDevice = tmp?[indexPath.row] {
            newDeviceCell?.configureWithItem(item: unwrappedDevice)
        }

        if let newDeviceCell = newDeviceCell {
            return newDeviceCell
        } else {
            return DeviceTableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let devicesInSection = searchActive ? filteredDictionaryDevices[letters[section]] : dictionaryDevices[letters[section]]
        if let devicesInSection = devicesInSection {
            return devicesInSection.count
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

extension DevicesViewController: UISearchBarDelegate {

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
        dictionaryDevices.forEach { (key, value) in
            filteredDictionaryDevices[key] = value.filter({ (device) -> Bool in
                let tmp: NSString = device.indexString as NSString
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

extension DevicesViewController {
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

extension Device {
    var indexString: String { return "\(name) [\(assetTag)]" }
}
