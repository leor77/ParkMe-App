
import Foundation
import FirebaseDatabase

protocol ParkerController: class {
    func acceptSpot(lat: Double, long: Double);
}
 

class ParkingHandler {
    static let _instance = ParkingHandler();
    
    weak var delegate: ParkerController?;
    
    var seller = "";
    var requester = "";
    var requester_id = "";
    var seller_id = "";
    
    static var Instance: ParkingHandler {
        return _instance;
    }
    
    func listenToRequests(){
        
        DBProvider.Instance.requestRef.observe(FIRDataEventType.childAdded){
            (snapshot: FIRDataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let latitude = data[Constants.LATITUDE] as?
                    Double {
                    if let longitude = data[Constants.LONGITUDE] as?
                        Double {
                        self.delegate?.acceptSpot(lat: latitude, long: longitude)
                    }
                }
            }
        }
    }
    
    
    func requestSpot(latitude: Double, longitude: Double){
        let data: Dictionary<String, Any> = [Constants.NAME: requester, Constants.LATITUDE: latitude, Constants.LONGITUDE: longitude];
        DBProvider.Instance.requestRef.childByAutoId().setValue(data);
    }
    
}
