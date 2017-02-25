
import UIKit
import MapKit
import FirebaseDatabase

class SpotLocationVC: UIViewController, MKMapViewDelegate {
    
    
    var requestLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var requestUsername = ""
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var purchaseSpotButton: UIButton!
    @IBAction func purchaseSpot(_ sender: Any) {
        
        // let ref = FIRDatabase.database().reference()
        
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
        
        
        
        
        
        
        
        
        
        
        
        
        
        //ref.queryOrdered(byChild: "Sell_Request").queryEqual(toValue: requestUsername).
            
//            { (FIRDataSnapshot) in
//            
//            if let data = FIRDataSnapshot.value as? NSDictionary {
//                if let name = data[Constants.NAME] as? String {

        
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
