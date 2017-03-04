
import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth

class SpotLocationVC: UIViewController, MKMapViewDelegate {
    
    
    var requestLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var requestUsername = ""
    var ref = FIRDatabase.database().reference()
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var purchaseSpotButton: UIButton!
    
    @IBAction func test(_ sender: Any) {
        
       // ref.child("Sell_Request").queryOrdered(byChild: "name").queryEqual(toValue: requestUsername).setValue("true", forKey: "Request_Made")
        
        ref.child("Sell_Request").queryOrdered(byChild: "name").queryEqual(toValue: requestUsername).observeSingleEvent(of: .value, with: { (snapshot : FIRDataSnapshot) in
            
            snapshot.setValue(true, forKey: "Request_Made");
            
            })
        }
    
    @IBAction func purchaseSpot(_ sender: Any) {
        
        let buyerLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
        
        CLGeocoder().reverseGeocodeLocation(buyerLocation, completionHandler: { (placemarks, error) in
            
            if let placemarks = placemarks {
                if placemarks.count > 0 {
                    let mKPlacemark = MKPlacemark(placemark: placemarks[0])
                    
                    let mapItem = MKMapItem(placemark: mKPlacemark)
                    mapItem.name = self.requestUsername
                    
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                    
                    mapItem.openInMaps(launchOptions: launchOptions)
                    
                }
            }
            
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = requestLocation
        annotation.title = "Available Spot: \(requestUsername)"
        
        mapView.addAnnotation(annotation)
        
    }
}
