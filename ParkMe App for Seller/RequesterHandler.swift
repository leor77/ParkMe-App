

import Foundation
import FirebaseDatabase

protocol ParkerController: class {
    func acceptSpot(lat: Double, long: Double);
}

class RequesterHandler {
    static let _instance = RequesterHandler();
    
    weak var delegate: ParkerController?;
    
    var requester = "";
    var requester_id = "";
    
    
    static var Instance: RequesterHandler {
        return _instance;
    }
    
    func listenToRequests(){
        
        DBProvider.Instance.sellRequestRef.observe(FIRDataEventType.childAdded){
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
    
    func acceptedParkingSpot(lat: Double, long: Double){
        let data: Dictionary<String, Any> = [Constants.NAME: requester, Constants.LATITUDE: lat, Constants.LONGITUDE: long]
        DBProvider.Instance.requestAccepted.childByAutoId().setValue(data)

}

}
