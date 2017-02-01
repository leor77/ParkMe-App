

import UIKit
import MapKit

class RiderVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, ParkerController {
    
@IBOutlet weak var myMap: MKMapView!
    
    private var locationManager = CLLocationManager();
    private var userLocation: CLLocationCoordinate2D?;
    private var parkingSpotLocation: CLLocationCoordinate2D?;
    private var requestAlive = false;
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        initializeLocationMgr();

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
            
            let annotation = MKPointAnnotation();
            annotation.coordinate = userLocation!;
            annotation.title = "Parking Spot Location";
            myMap.addAnnotation(annotation);
            
        }
    }

    @IBAction func requestSpot(_ sender: AnyObject) {
        
        ParkingHandler.Instance.requestSpot(latitude: Double(userLocation!.latitude), longitude: Double(userLocation!.longitude))
    }
    
    @IBAction func sellSpot(_ sender: Any) {
                
        RequesterHandler.Instance.delegate = self;
        RequesterHandler.Instance.listenToRequests();

    }
    
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
            let accept = UIAlertAction(title: "Accept?", style: .default, handler: { (alertAction: UIAlertAction)
                in
            });
            
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
