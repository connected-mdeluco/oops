# toybox-ios

## API Key

The .gitignore includes a file "Keys.plist" that contains the API key. In the SnipeAPIManager.swift file, we use the API key to make requests to Snipe-IT, but the Keys.plist file has been omitted for security reasons. To include the API key, create a Keys.plist file and add a string with the key "SnipeKey" and the value being the API key.

![alt text](https://github.com/connected-io/toybox-ios/blob/master/README_images/apikey.png)

## Classes

### QRCodeViewController

This is the main view controller where the user begins their navigation flow. QRCodeViewController handles segue methods and Borrow/Return button layouts.

### QRScannerViewController

This is the video capture view that scans the QR codes -- depending on what path the user has taken (borrow path or return path), this view will configure itself accordingly. Here, the video capture session is created in viewDidLoad, along with other view setup.

Snipe-API calls are made here for returning devices, borrowing devices, getting device names, and patching device asset names.

### AlphabeticalViewController

This view controller displays the list of employees. It makes a call to the Snipe-IT API to get the list of users.

### EmployeeTableViewCell

A class that represents the configuration of an Employee cell in the AlphabeticalViewController.

### SnipeAPIManager

This class handles all calls to the Snipe-IT API. 

### SnipeAPIResponseModels

These structures are modelled after the JSON responses received from Snipe-IT API calls. We use these to decode and parse the JSON responses into Swift structures so we can use the information. These models are used in the SnipeAPIManager.

### ErrorManager

Handles potential API errors, including instances where the API key becomes invalid. 

### StringLiterals

A file that holds all the string literals used in code. 
