

import UIKit
import Firebase
import FirebaseDatabase
import MapKit
import CoreLocation

class RequestVC: UITableViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet var Radius: [UIBarButtonItem]!
    @IBOutlet var mapView: MKMapView!
    
    var maxDistance: Double = 100
    var is_First: Bool = true

    var prices = [String]()
    var locationManager = CLLocationManager()
    var sellerUserNames = [String]() {
        didSet {
        }
    }
    var requestLocations = [CLLocationCoordinate2D]() {
        didSet {
        }
    }
    
//    @IBAction func setDistance(_ sender: Any) {
//        
//        let alert = UIAlertController(title: "Set maximum distance of desired parking spot", message: "", preferredStyle: .alert)
//        
//        alert.addTextField(configurationHandler: { (textField) in
//            textField.placeholder = "Enter Distance"
//        })
//        
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
//            print("Cancelled")
//        })
//        
//        alert.addAction(UIAlertAction(title: "Done", style: .default) { (action) in
//            print("Done")
//            
//            if let textField = alert.textFields?.first {
//                let maxDistance = textField.text
//                self.populateArrays()
//            }
//        })
//        
//        self.present(alert, animated: true, completion: nil)
//        
//            }
//    
    
    func loadMap() {
        
        let username = self.sellerUserNames.first
        let location = self.requestLocations.first
        let price = self.prices.first
        locationManager.location?.coordinate
        
        let region = MKCoordinateRegion(center: (locationManager.location?.coordinate)!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

        mapView.setRegion(region, animated: true)
        
        for i in 0 ..< requestLocations.count {
        
            let annotation = MKPointAnnotation()
            
            annotation.coordinate = requestLocations[i]
            
            let spotInfo = sellerUserNames[i] + " - $" + prices[i];
            
            annotation.title = spotInfo;
            mapView.addAnnotation(annotation)
        }
    }
    
    func sortLocations() {
        for i in 0 ..< requestLocations.count
        {
            for j in i + 1 ..< requestLocations.count {
                if getDistance(location: requestLocations[i]) > getDistance(location: requestLocations[j])
                {
                    let temp = requestLocations[i]
                    let temp1 = sellerUserNames[i]
                    let temp2 = prices[i]
                    requestLocations[i] = requestLocations[j]
                    requestLocations[j] = temp
                    sellerUserNames[i] = sellerUserNames[j]
                    sellerUserNames[j] = temp1
                    prices[i] = prices[j]
                    prices[j] = temp2
                }
            }
        }
    }
    
    func removeHighValues() {
        
        for i in 0 ..< requestLocations.count {
            
            if (Double(getDistance(location: requestLocations[i])) > maxDistance) {
                
                self.requestLocations.remove(at: i)
                self.sellerUserNames.remove(at: i)
                self.prices.remove(at: i)
            }
        }
    }
    
    func getDistance(location: CLLocationCoordinate2D) -> Double
    {
        let currentLocation = locationManager.location?.coordinate
        if currentLocation == nil {
            return 0
        }
        
        let buyerLocation = CLLocation(latitude: (currentLocation?.latitude)!, longitude: (currentLocation?.longitude)!)
        let sellerLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        let distance = buyerLocation.distance(from: sellerLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        let distanceInMiles = roundedDistance * 0.621
        let roundedDistanceInMiles = round(distanceInMiles * 1000) / 1000
        
        return roundedDistanceInMiles
    }
    
    func populateArrays(){
    
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child("Sell_Request").observe(FIRDataEventType.childAdded, with: { (FIRDataSnapshot) in
            
            if (self.is_First == true){

                self.is_First = false
            }
            
            if let data = FIRDataSnapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if let lat = data["latitude"] as? Double {
                        if let long = data["longitude"] as? Double {
                            if let price = data["Price"] as? String {
                                self.sellerUserNames.append(name)
                                self.requestLocations.append(CLLocationCoordinate2D(latitude: lat, longitude: long))
                                self.prices.append(price)
                                
                                self.sortLocations()
                                self.removeHighValues()
                                self.tableView.reloadData()
                                
                                self.loadMap()
                            }
                        }
                    }
                }
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "backToMain" {
            self.navigationController?.navigationBar.isHidden = true
        }
        else if segue.identifier == "showSpotLocation" {
            
            if let _destination = segue.destination as? SpotLocationVC {
                
                if let row = self.tableView.indexPathForSelectedRow?.row {
                    
                    let dist = getDistance(location: requestLocations[row])
                    
                    _destination.myLocation = (locationManager.location?.coordinate)!
                    _destination.requestLocation = requestLocations[row]
                    _destination.requestUsername = sellerUserNames[row]
                    _destination.price = prices[row];
                    _destination.distance = dist
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self as! MKMapViewDelegate
        
        is_First = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        populateArrays()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.sortLocations()
        self.tableView.reloadData()
    }

    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {        
        return sellerUserNames.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        tableView.separatorStyle = .none
        tableView.sectionIndexBackgroundColor = UIColor.blue
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.font = UIFont(name: "Avenir", size: 18)
        
        cell.selectedBackgroundView?.backgroundColor = UIColor.blue
        
        let roundedDistanceInMiles = getDistance(location: requestLocations[indexPath.row])
        
        cell.textLabel?.text = "$" + prices[indexPath.row] + " - \(roundedDistanceInMiles) miles away"
        cell.detailTextLabel?.font = UIFont(name: "Avenir", size: 12)
        cell.detailTextLabel?.text = sellerUserNames[indexPath.row]
        
        return cell
    }
    
}
