//
//  EmployeeTableViewCell.swift
//  QRCodeReader
//
//  Created by cl-dev on 2018-09-12.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit

class EmployeeTableViewCell: UITableViewCell {
    @IBOutlet weak private var name: UILabel!
    
    var employee: Employee = Employee(name:"Unknown", id:0)
    
    static var identifier = "employeeCell"
    
    func configureWithItem(item: Employee) {
        name?.text = item.name
        employee = item
    }
}
