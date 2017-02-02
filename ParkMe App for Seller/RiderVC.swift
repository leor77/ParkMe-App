

import UIKit
import MapKit

class RiderVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, ParkerController, sellerController {
    
@IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var sellParkingSpotButton: UIButton!
    
    
    private var locationManager = CLLocationManager();
    private var userLocation: CLLocationCoordinate2D?;
    private var requesterLocation: CLLocationCoordinate2D?;
    private var parkingSpotLocation: CLLocationCoordinate2D?;
    
    private var parkerCancelledRequest = false;
    private var acceptedSpot = false;
    private var canSellSpot = true;
    
    //private var timer = Timer()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        initializeLocationMgr()
        
        ParkingHandler.Instance.sellerListenToMsgs()
        ParkingHandler.Instance.delegate = self
        
    }
    
    private func initializeLocationMgr() {
        
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestWhenInUseAuthorization();
        locationManager.startUpdatingLocation();
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locationManager.location?.coordinate{
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude);
            let region = MKCoordinateRegion(center: userLocation!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01));
            
            
            
            myMap.setRegion(region, animated: true);
            myMap.removeAnnotations(myMap.annotations);
            
            if requesterLocation != nil {
                if !canSellSpot {
                    let requesterSpot = MKPointAnnotation()
                    requesterSpot.coordinate = requesterLocation!
                    requesterSpot.title = "Requester"
                    myMap.addAnnotation(requesterSpot)
                }
            }
            
            let annotation = MKPointAnnotation();
            annotation.coordinate = userLocation!;
            annotation.title = "Parking Spot Location";
            myMap.addAnnotation(annotation);
            
        }
    }
    
    func updateRequesterLocation(lat: Double, long: Double) {
        requesterLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    func canSellSpot(delegateCalled: Bool) {
        if (delegateCalled){
            sellParkingSpotButton.setTitle("Cancel", for: UIControlState.normal);
            canSellSpot = false;
        } else {
            sellParkingSpotButton.setTitle("Sell Parking Spot", for: UIControlState.normal)
            canSellSpot = true;
        }
    }
    
    func requesterAcceptedSpot(requestAccepted: Bool, requesterName: String) {
        if requestAccepted {
            alertUser(title: "Parking Spot Sold", message: "Your parking spot was sold to \(requesterName)")
        }
        
    }

    @IBAction func requestSpot(_ sender: AnyObject) {
            if (canSellSpot) {
                ParkingHandler.Instance.requestSpot(latitude: Double(userLocation!.latitude), longitude: Double(userLocation!.longitude))
            } else {
                parkerCancelledRequest = true;
                ParkingHandler.Instance.sellerCancelSpot();
            }
    } // Sell Parking Spot
    
    @IBAction func sellSpot(_ sender: Any) {
                
        RequesterHandler.Instance.delegate = self;
        RequesterHandler.Instance.listenToRequests();
        
    } // Request Parking Spot
    
    func acceptSpot(lat: Double, long: Double) {

        parkingSpotRequest(title: "Spot Request", message: "You have a spot available at this location: Lat: \(lat), Long: \(long)", requestAlive: true);
    }
    
    @IBAction func logout(_ sender: Any) {
        
        if (AuthProvider.Instance.logOut()){
            dismiss(animated: true, completion: nil);
        } else {
            alertUser(title: "Could not Logout", message: "Unable to logout at the moment");
        }
    }
    
    private func parkingSpotRequest(title: String, message: String, requestAlive: Bool){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        if requestAlive {
            let accept = UIAlertAction(title: "Accept", style: .default, handler: { (alertAction: UIAlertAction)
                in
                
                self.acceptedSpot = true;
                
                RequesterHandler.Instance.acceptedParkingSpot(lat: Double(self.userLocation!.latitude), long: Double(self.userLocation!.longitude))
                
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil);
            
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
}
