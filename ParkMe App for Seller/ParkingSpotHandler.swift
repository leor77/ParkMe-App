
// Handler for those wanting to sell their parking spot

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
    var seller_id = "";
    
    static var Instance: ParkingHandler {
        return _instance;
    }
    
    func sellerListenToMsgs() {
        DBProvider.Instance.sellRequestRef.observe(FIRDataEventType.childAdded) { (snapshot : FIRDataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if name == self.seller {
                        self.seller_id = snapshot.key;
                        self.delegate?.canSellSpot(delegateCalled: true)
                    }
                }
            }
        }
        
        DBProvider.Instance.sellRequestRef.observe(FIRDataEventType.childRemoved) { (snapshot: FIRDataSnapshot) in
        
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if name == self.seller {
                        self.delegate?.canSellSpot(delegateCalled: false)
                    }
                }
            }
        }
    
    }
    
    func requestSpot(latitude: Double, longitude: Double){
        let data: Dictionary<String, Any> = [Constants.NAME: seller, Constants.LATITUDE: latitude, Constants.LONGITUDE: longitude];
        DBProvider.Instance.sellRequestRef.childByAutoId().setValue(data);
    }
    
    func sellerCancelSpot(){
        DBProvider.Instance.sellRequestRef.child(seller_id).removeValue();
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
