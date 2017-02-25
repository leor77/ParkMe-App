
import UIKit
import MapKit
import FirebaseDatabase

class SpotLocationVC: UIViewController, MKMapViewDelegate {
    
    
    var requestLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var requestUsername = ""
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var purchaseSpotButton: UIButton!
    @IBAction func purchaseSpot(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = requestLocation
        annotation.title = "Available Spot: \(requestUsername)"
        
        mapView.addAnnotation(annotation)
        
    }
}
