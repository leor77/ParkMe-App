
import UIKit
import MapKit
import Firebase
import FirebaseDatabase
import CoreLocation
class RequestVController: UIViewController, UITableViewDelegate,UITableViewDataSource,MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self as! MKMapViewDelegate
        
        is_First = true
        
        locationManager.delegate = self as! CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        populateArrays()
        
    }
    
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
//            let alert = UIAlertController(title: "Set maximum distance of desired parking spot", message: "", preferredStyle: .alert)
//    
//            alert.addTextField(configurationHandler: { (textField) in
//                textField.placeholder = "Enter Distance"
//            })
//    
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
//                print("Cancelled")
//            })
//    
//            alert.addAction(UIAlertAction(title: "Done", style: .default) { (action) in
//                print("Done")
//    
//                if let textField = alert.textFields?.first {
//                    let maxDistance = textField.text
//                    self.populateArrays()
//                }
//            })
//    
//            self.present(alert, animated: true, completion: nil)
//        }

    
    func loadMap() {
        
        if (!requestLocations.isEmpty) {
    
    let firstUser = self.requestLocations.first
        
    let region = MKCoordinateRegion(center: (firstUser)!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)
        mapView.showsBuildings = true
        mapView.showsScale = true
        mapView.showsTraffic = true
            
        mapView.setRegion(region, animated: true)
            
            for i in 0 ..< requestLocations.count {
                
                let annotation = MKPointAnnotation()
                
                annotation.coordinate = requestLocations[i]
                
                let spotInfo = sellerUserNames[i] + " - $" + prices[i];
                
                annotation.title = spotInfo;
                mapView.addAnnotation(annotation)
            }
        }
        
        else {
        
            let currentLocation = locationManager.location?.coordinate
            
            let region = MKCoordinateRegion(center: (currentLocation)!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            mapView.setRegion(region, animated: true)
            mapView.showsBuildings = true
            mapView.showsScale = true
            mapView.showsTraffic = true

            }
        }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    func removeDeletedItems() {
    
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child("Sell_Request").observe(FIRDataEventType.childRemoved, with: { (FIRDataSnapshot) in
            
            guard let data = FIRDataSnapshot.value as? [String: Any],
            let emailToFind = data[Constants.NAME] as? String else { return }
            
            if let index = self.sellerUserNames.index(of: emailToFind) {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.sellerUserNames.remove(at: index)
                    self.requestLocations.remove(at: index)
                    self.prices.remove(at: index)
                    self.tableView.deleteRows(at: [indexPath], with: .none)
                
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    self.loadMap()
            }
        })
        
    
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
                                self.removeDeletedItems()
                                
                                self.tableView.reloadData()
                                
                                if (!self.sellerUserNames.isEmpty) {
                                self.loadMap()
                                }
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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.sortLocations()
        self.tableView.reloadData()
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sellerUserNames.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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


//    func loadMap() {
//
//        if let firstUser = self.requestLocations.first {
//
//            let region = MKCoordinateRegion(center: (firstUser), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//
//        mapView.setRegion(region, animated: true)
//        mapView.showsBuildings = true
//        mapView.showsScale = true
//        mapView.showsTraffic = true
//
//            mapView.setRegion(region, animated: true)
//
//            for i in 0 ..< requestLocations.count {
//
//                let annotation = MKPointAnnotation()
//
//                annotation.coordinate = requestLocations[i]
//
//                let spotInfo = sellerUserNames[i] + " - $" + prices[i];
//
//                annotation.title = spotInfo;
//                mapView.addAnnotation(annotation)
//            }
//
//        }
//
//        else {
//
//            let currentLocation = self.locationManager.location?.coordinate
//
//            let region = MKCoordinateRegion(center: currentLocation!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//
//
//        mapView.setRegion(region, animated: true)
//
//        for i in 0 ..< requestLocations.count {
//
//            let annotation = MKPointAnnotation()
//
//            annotation.coordinate = requestLocations[i]
//
//            let spotInfo = sellerUserNames[i] + " - $" + prices[i];
//
//            annotation.title = spotInfo;
//            mapView.addAnnotation(annotation)
//        }
//        }
//    }













