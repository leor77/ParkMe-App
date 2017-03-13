
import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth

class SpotLocationVC: UIViewController, MKMapViewDelegate {
    
    
    var requestLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var requestUsername = ""
    var ref = FIRDatabase.database().reference()
    
    let user = FIRAuth.auth()?.currentUser
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var purchaseSpotButton: UIButton!
    
    @IBAction func purchaseSpot(_ sender: Any) {
        
        let buyerName = user?.email
        
        if (buyerName != requestUsername){  // Make sure buyer is not purchasing their own spot
            
            ref.child("Sell_Request").queryOrdered(byChild: "name").queryEqual(toValue: requestUsername).observe(.value, with: { dataSnapshot in
                let enumerator = dataSnapshot.children
                while let sell_request = enumerator.nextObject() as? FIRDataSnapshot {
                    sell_request.ref.child("Request_Made").setValue(true)
                    sell_request.ref.child("Current_Requester").setValue(buyerName)
                    sell_request.ref.child("buyer_latitude").setValue(self.requestLocation.latitude)
                    sell_request.ref.child("buyer_longitude").setValue(self.requestLocation.longitude)
                    
                }
            })
        }
        
        
        /*
            let buyerLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
            let data: Dictionary<String, Any> = [Constants.NAME: ParkingHandler.Instance.seller, Constants.SELLER: self.requestUsername];
            DBProvider.Instance.requestAccepted.childByAutoId().setValue(data);
        
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
    */
}


}





