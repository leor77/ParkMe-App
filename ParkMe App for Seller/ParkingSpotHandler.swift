
import Foundation
import FirebaseDatabase

class ParkingHandler {
    static let _instance = ParkingHandler();
    
    var seller = "";
    var requester = "";
    var requester_id = "";
    var seller_id = "";
    
    static var Instance: ParkingHandler {
        return _instance;
    }
    
    func requestSpot(latitude: Double, longitude: Double){
        let data: Dictionary<String, Any> = [Constants.NAME: requester, Constants.LATITUDE: latitude, Constants.LONGITUDE: longitude];
        DBProvider.Instance.requestRef.childByAutoId().setValue(data);
    }
    
}
