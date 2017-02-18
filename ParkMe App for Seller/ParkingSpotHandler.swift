
import Foundation
import FirebaseDatabase
import FirebaseAuth

protocol sellerController: class {
    func canSellSpot(delegateCalled:Bool)
    func updateRequesterLocation(lat: Double, long: Double)
}

class ParkingHandler {
    static let _instance = ParkingHandler();
    
    weak var delegate: sellerController?;
    
    var seller = "";
    var requester = "";
    var requester_id = "";
    var seller_id = "";
    
    
    
    static var Instance: ParkingHandler {
        return _instance;
    }
    
    func sellerListenToMsgs() {
        DBProvider.Instance.requestRef.observe(FIRDataEventType.childAdded) { (snapshot : FIRDataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if name == self.requester {
                        self.requester_id = snapshot.key;
                        self.delegate?.canSellSpot(delegateCalled: true)
                    }
                }
            }
        }
        
        DBProvider.Instance.requestRef.observe(FIRDataEventType.childRemoved) { (snapshot: FIRDataSnapshot) in
        
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if name == self.requester {
                        self.delegate?.canSellSpot(delegateCalled: false)
                    }
                }
            }
        }
     
//        DBProvider.Instance.requestAccepted.observe(FIRDataEventType.childAdded) { (snapshot: FIRDataSnapshot) in
//            
//            if let data = snapshot.value as? NSDictionary {
//                if let name = data[Constants.NAME] as? String {
//                    if self.requester == "" {
//                        self.requester = name;
//                        self.delegate?.requesterAcceptedSpot(requestAccepted: true, requesterName: self.requester)
//                    }
//                }
//            }
//        }
//
    
    }
    
    func requestSpot(latitude: Double, longitude: Double){
        let data: Dictionary<String, Any> = [Constants.NAME: requester, Constants.LATITUDE: latitude, Constants.LONGITUDE: longitude];
        DBProvider.Instance.requestRef.childByAutoId().setValue(data);
    }
    
    func sellerCancelSpot(){
        DBProvider.Instance.requestRef.child(requester_id).removeValue();
    }
} // 
