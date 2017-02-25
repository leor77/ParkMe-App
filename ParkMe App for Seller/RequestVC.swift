

import UIKit
import Firebase
import FirebaseDatabase
import MapKit
import CoreLocation

class RequestVC: UITableViewController, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var sellerUserNames = [String]()
    var requestLocations = [CLLocationCoordinate2D]()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "backToMain" {
            self.navigationController?.navigationBar.isHidden = true
        }
        else if segue.identifier == "showSpotLocation" {
            
            if let _destination = segue.destination as? SpotLocationVC {
            
                if let row = self.tableView.indexPathForSelectedRow?.row {
                
                _destination.requestLocation = requestLocations[row]
                _destination.requestUsername = sellerUserNames[row]
                
                }
            }
        }
    } 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child("Sell_Request").observe(FIRDataEventType.childAdded, with: { (FIRDataSnapshot) in
            
            if let data = FIRDataSnapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if let lat = data["latitude"] as? Double {
                        if let long = data["longitude"] as? Double {
                            
                            print("\(self.sellerUserNames) Location: Latitude: \(lat), Longitude: \(long)")
                            
                            self.sellerUserNames.append(name)
                            self.requestLocations.append(CLLocationCoordinate2D(latitude: lat, longitude: long))
                            
                            self.tableView.reloadData()
                            
                        }
                    }
                }
            }
        })
    }


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return sellerUserNames.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Find distance b/w user locations -  requestLocations[indexPath.row]
        
        let location = locationManager.location?.coordinate
        
        let buyerLocation = CLLocation(latitude: (location?.latitude)!, longitude: (location?.longitude)!)
        
        let sellerLocation = CLLocation(latitude: requestLocations[indexPath.row].latitude, longitude: requestLocations[indexPath.row].longitude)
        
        let distance = buyerLocation.distance(from: sellerLocation) / 1000
        
        let roundedDistance = round(distance * 100) / 100
        
        let distanceInMiles = roundedDistance * 0.621
        let roundedDistanceInMiles = round(distanceInMiles * 1000) / 1000

        
        cell.textLabel?.text = sellerUserNames[indexPath.row] + " - \(roundedDistanceInMiles) miles away"
     
        return cell
    }
}
