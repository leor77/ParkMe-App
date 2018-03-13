
import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase

class RiderVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, ParkerController, sellerController {
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var sellParkingSpotButton: UIButton!
    
    private var locationManager = CLLocationManager();
    private var userLocation: CLLocationCoordinate2D?;
    private var buyerLocation: CLLocationCoordinate2D?;
    private var parkingSpotLocation: CLLocationCoordinate2D?;
    
    private var parkerCancelledRequest = false;
    private var acceptedSpot = false;
    private var canSellSpot = true;
    var tField: UITextField!
    private var price = ""
    
    let user = FIRAuth.auth()?.currentUser

    fileprivate var didShowNearbyAlert = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        initializeLocationMgr()

        ParkingHandler.Instance.delegate = self
        ParkingHandler.Instance.sellerListenToMsgs()
        
        RequesterHandler.Instance.delegate = self;
        RequesterHandler.Instance.listenToRequests();

        myMap.delegate = self
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didShowNearbyAlert = false
    }
    
    private func initializeLocationMgr() {
        
        locationManager.delegate = self;
        locationManager.requestAlwaysAuthorization();
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.startUpdatingLocation();
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locationManager.location?.coordinate{
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude);
            
            myMap.removeAnnotations(myMap.annotations);
            
            if buyerLocation != nil {
                if !canSellSpot {
                    let buyerSpot = MKPointAnnotation()
                    buyerSpot.coordinate = buyerLocation!
                    buyerSpot.title = "Buyer"
                    myMap.addAnnotation(buyerSpot)
                    
                    let latDelta = abs((userLocation?.latitude)! - (buyerLocation?.latitude)!) * 2 + 0.005
                    let longDelta = abs((userLocation?.longitude)! - (buyerLocation?.longitude)!) * 2 + 0.005
                    let region = MKCoordinateRegion(center: userLocation!, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta));
                    myMap.setRegion(region, animated: true);
                } else {
                    let region = MKCoordinateRegion(center: userLocation!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01));
                    myMap.setRegion(region, animated: true);
                }
            } else {
                let region = MKCoordinateRegion(center: userLocation!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01));
                myMap.setRegion(region, animated: true);
            }
            
            let annotation = MKPointAnnotation();
            annotation.coordinate = userLocation!;
            annotation.title = "Parking Spot Location";
            myMap.addAnnotation(annotation);

            guard let userLocation = userLocation,
                let buyerLocation = buyerLocation else {
                    return
            }


            let sourceLocation = CLLocation(latitude: buyerLocation.latitude, longitude: buyerLocation.longitude)
            let destinationLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)

            let sourcePlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(sourceLocation.coordinate.latitude), longitude: CLLocationDegrees(sourceLocation.coordinate.longitude)), addressDictionary: nil)
            let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(destinationLocation.coordinate.latitude), longitude: CLLocationDegrees(destinationLocation.coordinate.longitude)), addressDictionary: nil)

            let request = MKDirectionsRequest()
            request.source = MKMapItem(placemark: sourcePlacemark)
            request.destination = MKMapItem(placemark: destinationPlacemark)
            request.transportType = .any
            request.requestsAlternateRoutes = true
            let directions = MKDirections(request: request)
            directions.calculate { [unowned self] response, error in
                self.myMap.removeOverlays(self.myMap.overlays)

                guard let route = response?.routes.first else {
                    return
                }
                
                self.myMap.add(route.polyline, level: .aboveRoads)
                    
            }
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
    
    // GPS location updating function for seller
    
    func updateRequesterLocation(lat: Double, long: Double) {
        
        buyerLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        DBProvider.Instance.sellRequestRef.queryOrdered(byChild: "name").queryEqual(toValue: self.user?.email).observe(FIRDataEventType.childChanged) { (snapshot: FIRDataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                
                if let buyer_arrived = data["buyer_arrived"] as? Bool {
                    
                    if buyer_arrived == true {
                        
                        print("ALERT #2")
                        
                        let alert = UIAlertController(title: "Buyer Arrival", message: "Your buyer has arrived. You may now vacate your spot. Have a nice day!.", preferredStyle: .alert);
                        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil);
                        alert.addAction(ok);
                        self.present(alert, animated: true, completion: nil);
                        
                        self.canSellSpot = true;
                        self.parkerCancelledRequest = true;
                        self.buyerLocation = nil
                        ParkingHandler.Instance.sellerCancelSpot()
                        ParkingHandler.Instance.stopAllObservers()
                        self.myMap.removeOverlays(self.myMap.overlays)
                        
                        self.restartListeners()
                        
                    }
                }
            }
        }
        
        if userLocation != nil {
        
            let user = CLLocation(latitude: (userLocation?.latitude)!, longitude: (userLocation?.longitude)!)
            let buyer = CLLocation(latitude: (buyerLocation?.latitude)!, longitude: (buyerLocation?.longitude)!)
            let distance = buyer.distance(from: user)

            print("seller: .f", distance)
            
            if distance <= 6 && !self.didShowNearbyAlert {
                
                self.didShowNearbyAlert = true;
                
                print("ALERT #1")
                
                DBProvider.Instance.buyRequestRef.queryOrdered(byChild: "seller_name").queryEqual(toValue: self.user?.email).observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
                    let enumerator = snapshot.children
                    
                    while let buy_request = enumerator.nextObject() as? FIRDataSnapshot {
                        
                        let data = buy_request.value as? NSDictionary
                        if let arrived = data?["arrived"] as? Bool {
                            
                            if arrived == false {
                
                let alert = UIAlertController(title: "Buyer Arrival", message: "Your buyer has arrived. You may now vacate your spot. Have a nice day!.", preferredStyle: .alert);
                let ok = UIAlertAction(title: "Ok", style: .default, handler: nil);
                alert.addAction(ok);
                self.present(alert, animated: true, completion: nil);
                                                
                self.canSellSpot = true;
                self.parkerCancelledRequest = true;
                self.buyerLocation = nil
                ParkingHandler.Instance.sellerCancelSpot()
                ParkingHandler.Instance.stopAllObservers()
                self.myMap.removeOverlays(self.myMap.overlays)
                                
                self.restartListeners()
                                
                            }
                        }
                    }
                })}}}
    
    func canSellSpot(delegateCalled: Bool) {
        if (delegateCalled){
            sellParkingSpotButton.setTitle("Cancel", for: UIControlState.normal);
            canSellSpot = false;
        } else {
            sellParkingSpotButton.setTitle("Sell Parking Spot", for: UIControlState.normal)
            canSellSpot = true;
        }
        didShowNearbyAlert = false
    }
    
    func requesterAcceptedSpot(requestAccepted: Bool, requesterName: String) {
        if requestAccepted {
            alertUser(title: "Parking Spot Sold", message: "Your parking spot was sold to \(requesterName)")
        }
    }
    
    @IBAction func sellSpot(_ sender: Any) {
        
        if (canSellSpot) {
            
            let currentID = user?.uid
            let currentName = user?.email
            
            let alert = UIAlertController(title: "Set price of parking spot", message: "", preferredStyle: .alert)
            
            alert.addTextField(configurationHandler: { (textField) in
                print("generating textField")
                textField.placeholder = "Enter amount"
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                print("Cancelled")
            })
            
            alert.addAction(UIAlertAction(title: "Done", style: .default) { (action) in
                print("Done")
                
                if let textField = alert.textFields?.first {
                   // print("Amount: \(textField.text)")
                    
                    let num = Double(textField.text!)
                    
                    if num != nil {
                        
                        ParkingHandler.Instance.sellSpot(user_ID: currentID!, name: currentName!, requestMade: false, currentRequest: "", price: textField.text!, latitude: Double(self.userLocation!.latitude), longitude: Double(self.userLocation!.longitude))
                        
                    }
                    
                    else {
                    
                        let alert = UIAlertController(title: "Error", message: "Please enter a valid price.", preferredStyle: .alert);
                        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil);
                        alert.addAction(ok);
                        self.present(alert, animated: true, completion: nil);
                    
                    }
                }
            })
            
            self.present(alert, animated: true, completion: nil)
        }
    
    else {
            parkerCancelledRequest = true;
            ParkingHandler.Instance.sellerCancelSpot();
        }
    }


    @IBAction func requestSpot(_ sender: Any) {
        RequesterHandler.Instance.delegate = self;
        RequesterHandler.Instance.listenToRequests();
        
    }
    
    func acceptSpot(lat: Double, long: Double, buyer: String, dist: Double, price: String) {
        
        parkingSpotRequest(title: "Purchase Request", message: "You have an offer from \(buyer) for $\(price), who is \(dist) miles away", requestAlive: true, buyer: buyer);

    } // Works
    
    func acceptOffer(lat: Double, long: Double, name: String) {
        parkingSpotRequest(title: "Purchase Request", message: "You have an offer from someone at this location: Lat: \(lat), Long: \(long)", requestAlive: true, buyer: name);
    }
    
    @IBAction func logout(_ sender: Any) {
        
        if (AuthProvider.Instance.logOut()){
            dismiss(animated: true, completion: nil);
        } else {
            alertUser(title: "Could not Logout", message: "Unable to logout at the moment");
        }
    }
    
    @IBAction func switchToRequests(_ sender: Any) {
        self.performSegue(withIdentifier: "showRequestVC", sender: nil)
    }
    
    
    private func parkingSpotRequest(title: String, message: String, requestAlive: Bool, buyer: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        if requestAlive {
            let accept = UIAlertAction(title: "Accept", style: .default, handler: { (alertAction: UIAlertAction)
                in
                
                self.acceptedSpot = true;
                                
                ParkingHandler.Instance.acceptOffer(buyer: buyer, accept: true)
                ParkingHandler.Instance.listenBuyerLocation(buyer: buyer)
                
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (alertAction: UIAlertAction) in
                ParkingHandler.Instance.acceptOffer(buyer: buyer, accept: false)
            });
            
            alert.addAction(accept);
            alert.addAction(cancel);
        } else {
            let ok = UIAlertAction(title: "Ok", style: .default, handler: nil);
            alert.addAction(ok);
        }
        
        present(alert, animated: true, completion: nil);
    }
    
    private func alertUser(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil);
        alert.addAction(ok);
        present(alert, animated: true, completion: nil);
    }
    
    func refreshView() ->() {
    
    self.viewDidLoad()
    self.viewWillAppear(true)
    
    }
    
    func restartListeners() {
    
        ParkingHandler.Instance.delegate = self
        ParkingHandler.Instance.sellerListenToMsgs()
        
        RequesterHandler.Instance.delegate = self;
        RequesterHandler.Instance.listenToRequests();
    
    }
    
}
