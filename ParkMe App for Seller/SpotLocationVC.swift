
import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth
import MBProgressHUD
import SwiftLocation


class SpotLocationVC: UIViewController, MKMapViewDelegate {
    
    var myLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var requestLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var requestUsername = ""
    var price = ""
    var distance = 0.0
    
    let when = DispatchTime.now() + 8
    
    var ref = FIRDatabase.database().reference()
    let user = FIRAuth.auth()?.currentUser
    
    var canBuySpot = true
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var purchaseSpotButton: UIButton!
    
    fileprivate var didShowNearbyAlert = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = requestLocation
        let spotInfo = requestUsername + " - $" + price;
        
        annotation.title = spotInfo;
        
        mapView.addAnnotation(annotation)
        

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        
        let buyername = self.user?.email
        let sellername = self.requestUsername
        let mergedname = "\(buyername)_\(sellername)"
        UserDefaults.standard.set(false, forKey: mergedname)
        UserDefaults.standard.synchronize()

        print("aaa")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(false)
        
        let buyername = self.user?.email
        let sellername = self.requestUsername
        let mergedname = "\(buyername)_\(sellername)"
        UserDefaults.standard.set(false, forKey: mergedname)
        UserDefaults.standard.synchronize()

        print("bbb")
    }

    
    // GPS location updating for Buyer
    
    func updateLocation() {
        
        Location.getLocation(accuracy: .city, frequency: .continuous, success: { (_, location) in
            
            print("A new update of location is available: \(location)")
            
            let sourceLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let destinationLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
            
            print("distance-333");
            
            
            var temp_distance = sourceLocation.distance(from: destinationLocation)
            print("buyer: .f", temp_distance)
            
            DBProvider.Instance.buyRequestRef.queryOrdered(byChild: "seller_name").queryEqual(toValue: self.requestUsername).observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
                let enumerator = snapshot.children
            
                while let buy_request = enumerator.nextObject() as? FIRDataSnapshot {
                
                    let data = buy_request.value as? NSDictionary
                    
                    if let accepted = data?["accepted"] as? Bool {
                        
                        if accepted == true {
                            buy_request.ref.child(Constants.LATITUDE).setValue(location.coordinate.latitude)
                            buy_request.ref.child(Constants.LONGITUDE).setValue(location.coordinate.longitude)
                            }
                            
                        if sourceLocation.distance(from: destinationLocation) <= 10 && !self.didShowNearbyAlert {
                            
                            buy_request.ref.child("arrived").setValue(true)
                            self.didShowNearbyAlert = true
                            self.canBuySpot(delegateCalled: false)
                            self.purchaseSpotButton.setTitle("Purchase Spot", for: UIControlState.normal)
                            
                            let alert = UIAlertController(title: "Arrival at Parking Spot", message: "You have arrived at your destination. Have a nice day!", preferredStyle: .alert)
                            
                            alert.addAction(UIAlertAction(title: "OK", style: .default) { (action) in
                            print("Deleting Buy Requests")
                                })
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                                self.deleteAllBuyRequests()
                            })
                            
                            self.present(alert, animated: true, completion: nil)
                            self.buyerArrived()
                            
                                }
                            
                            let sourcePlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(sourceLocation.coordinate.latitude), longitude: CLLocationDegrees(sourceLocation.coordinate.longitude)), addressDictionary: nil)
                            let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(destinationLocation.coordinate.latitude), longitude: CLLocationDegrees(destinationLocation.coordinate.longitude)), addressDictionary: nil)
                            
                            let request = MKDirectionsRequest()
                            request.source = MKMapItem(placemark: sourcePlacemark)
                            request.destination = MKMapItem(placemark: destinationPlacemark)
                            request.transportType = .any
                            request.requestsAlternateRoutes = true
                            let directions = MKDirections(request: request)
            
                            if (!self.didShowNearbyAlert) {
                            directions.calculate { [unowned self] response, error in
                                self.mapView.removeOverlays(self.mapView.overlays)
                                guard let route = response?.routes.first else {
                                    return
                                }
                                
                                self.mapView.add(route.polyline, level: .aboveRoads)
                                } }}}
                })
            }) { (request, last, error) in
                request.cancel()
                print("Location monitoring failed due to an error \(error)")
            }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            
            renderer.strokeColor = .blue
            renderer.lineWidth = 5
            
            return renderer
        }
        
        return MKOverlayRenderer()
    }
    
    @IBAction func purchaseSpot(_ sender: Any) {
        
        if (canBuySpot) {
            
            var didTapResponseAlert = false
            
            let buyerName = user?.email

            print("1");
            
            if (buyerName != requestUsername) {
        
                self.canBuySpot(delegateCalled: true)
                
                let progressView = MBProgressHUD.showAdded(to: self.view, animated: true)
                progressView.label.text = "Please wait while we contact seller..."
                
                DispatchQueue.main.asyncAfter(deadline: self.when) {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }

                
                let data: Dictionary<String, Any> = ["user_ID": user?.uid, "name": buyerName, "seller_name": requestUsername, "Price": price, "Distance": distance, Constants.LATITUDE: self.myLocation.latitude, Constants.LONGITUDE: self.myLocation.longitude, "arrived": false, "time": FIRServerValue.timestamp()];
                
                DBProvider.Instance.buyRequestRef.childByAutoId().setValue(data);
                
                print("2");

                DBProvider.Instance.buyRequestRef.queryOrdered(byChild: "seller_name").queryEqual(toValue: self.requestUsername).observe(FIRDataEventType.childChanged) {
                    (snapshot: FIRDataSnapshot) in
                    
                    print("3");

                    if didTapResponseAlert {
                        print("4");

                        return
                    }
                    
                    print("5");

                    if let data = snapshot.value as? NSDictionary {
                        if let name = data["name"] as? String {
                            if name == self.user?.email {
                                if let accepted = data["accepted"] as? Bool {
     
                                    print("6");

                                    let buyername = self.user?.email
                                    let sellername = self.requestUsername
                                    let mergedname = "\(buyername)_\(sellername)"

                                    if(!UserDefaults.standard.bool(forKey: mergedname)) { // First response
                                        
                                        print("7");

                                        UserDefaults.standard.set(true, forKey: mergedname)
                                        UserDefaults.standard.synchronize()
                                    
                                        let alert = UIAlertController(title: accepted ? "Accepted" : "Rejected", message: accepted ? "Seller accepted your request" : "Seller canceled your request", preferredStyle: .alert);
                                        
                                        let ok = UIAlertAction(title: "Ok", style: .default, handler: {(action: UIAlertAction) in
                                            didTapResponseAlert = true
                                            
                                            if accepted == true {
                                                
                                                self.updateLocation()
                                                
                                                let buyerLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
                                                
                                                CLGeocoder().reverseGeocodeLocation(buyerLocation, completionHandler: { (placemarks, error) in
                                                    if let placemarks = placemarks {
                                                        if placemarks.count > 0 {
                                                            let mKPlacemark = MKPlacemark(placemark: placemarks[0])
                                                            let mapItem = MKMapItem(placemark: mKPlacemark)
                                                            mapItem.name = self.requestUsername
                                                            
                                                            let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                                            
                                                            if !self.didShowNearbyAlert {
                                                                mapItem.openInMaps(launchOptions: launchOptions)
                                                            }
                                                        }
                                                    }
                                                })
                                            }
                                            
                                            else if accepted == false { // Seller rejects buyer
                                                
                                                    self.canBuySpot = true
                                                    self.deleteAllBuyRequests()
                                                    self.buyerCancelledSpot()
                                                    self.purchaseSpotButton.setTitle("Purchase Spot", for: UIControlState.normal)
                                            }
                                        });
                                        
                                        alert.addAction(ok);
                                        self.present(alert, animated: true, completion: nil);

                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        else { // Cancel
            canBuySpot = true
            self.deleteAllBuyRequests()
            self.buyerCancelledSpot()
            self.purchaseSpotButton.setTitle("Purchase Spot", for: UIControlState.normal)
        }
    }

    
    func deleteAllBuyRequests() {
        
        DBProvider.Instance.buyRequestRef.queryOrdered(byChild: "seller_name").queryEqual(toValue: self.requestUsername).observeSingleEvent(of: .value) {
            (snapshot: FIRDataSnapshot) in
            
            for child in snapshot.children {
                if let item = child as? FIRDataSnapshot {
                    item.ref.removeValue()
                }}
        }
    }
    
    func canBuySpot(delegateCalled: Bool) {
        if (delegateCalled){
            purchaseSpotButton.setTitle("Cancel", for: UIControlState.normal);
            canBuySpot = false;
        } else {
            purchaseSpotButton.setTitle("Purchase Spot", for: UIControlState.normal)
            canBuySpot = true;
        }
    }
    
    func buyerArrived() {
    
        DBProvider.Instance.sellRequestRef.queryOrdered(byChild: "name").queryEqual(toValue: self.requestUsername).observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
            let enumerator = snapshot.children
            
            while let buy_request = enumerator.nextObject() as? FIRDataSnapshot {
                buy_request.ref.child("buyer_arrived").setValue(true)
                
            }})
    
    }
    
    
    func buyerCancelledSpot(){
    
        DBProvider.Instance.buyRequestRef.queryOrdered(byChild: "name").queryEqual(toValue: self.user?.email).observeSingleEvent(of: .value) {
            (snapshot: FIRDataSnapshot) in
            
            for child in snapshot.children {
                if let item = child as? FIRDataSnapshot {
                    item.ref.removeValue()
                }}
        }

        let buyername = self.user?.email
        let sellername = self.requestUsername
        let mergedname = "\(buyername)_\(sellername)"
        UserDefaults.standard.set(false, forKey: mergedname)
        UserDefaults.standard.synchronize()

    }
    
}


//            if sourceLocation.distance(from: destinationLocation) <= 5 && !self.didShowNearbyAlert {
//                self.presentAlert(title: "Arrival at Parking Spot", message: "You have arrived at your destination. Have a nice day!")
//                self.didShowNearbyAlert = true
//                self.canBuySpot(delegateCalled: false)
//                self.purchaseSpotButton.setTitle("Purchase Spot", for: UIControlState.normal)
//
//                self.deleteAllBuyRequests()


//                DBProvider.Instance.buyRequestRef.queryOrdered(byChild: "seller_name").queryEqual(toValue: self.requestUsername).observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
//                    let enumerator = snapshot.children
//
//                    while let buy_request = enumerator.nextObject() as? FIRDataSnapshot {
//
//                        let data = buy_request.value as? NSDictionary
//
//                        if let arrived = data?["arrived"] as? Bool {
//
//                            if arrived == true {
//
//
//                            }
//                        }
//                    }
//                })
//






