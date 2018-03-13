
import Foundation
import FirebaseDatabase
import FirebaseAuth

protocol sellerController: class {
    func canSellSpot(delegateCalled:Bool)
    func updateRequesterLocation(lat: Double, long: Double)
    func acceptOffer(lat: Double, long: Double, name: String)
}

class ParkingHandler {
    static let _instance = ParkingHandler();
    
    weak var delegate: sellerController?;
    
    var seller = "";
    var seller_id = "";
    
    let when = DispatchTime.now() + 10
    
    
    let user = FIRAuth.auth()?.currentUser
    
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

    func sellSpot(user_ID: String, name: String, requestMade: Bool, currentRequest: String, price: String, latitude: Double, longitude: Double){

        let data: Dictionary<String, Any> = ["user_ID": user_ID, "name": name, "Price": price, Constants.LATITUDE: latitude, Constants.LONGITUDE: longitude];
        DBProvider.Instance.sellRequestRef.childByAutoId().setValue(data);
    } // Seller sells spot
    
    func sellerCancelSpot(){
        DBProvider.Instance.sellRequestRef.child(seller_id).removeValue();
    }
    
    func acceptOffer(buyer: String, accept: Bool){
        
        DBProvider.Instance.buyRequestRef.queryOrdered(byChild: "seller_name").queryEqual(toValue: self.seller).observeSingleEvent(of: .value, with: { dataSnapshot in
            let enumerator = dataSnapshot.children
           
            while let buy_request = enumerator.nextObject() as? FIRDataSnapshot {
               
                let data = buy_request.value as? NSDictionary
               
                if (data?["name"] as? String) == buyer {
                    
                    buy_request.ref.child("accepted").setValue(accept)
                    
                    if accept == true {
                       
                        self.delegate?.updateRequesterLocation(lat: data?["latitude"] as! Double, long: data?["longitude"] as! Double)
                    }
                }
                else if (data?["name"] as? String) != buyer {
                    buy_request.ref.child("accepted").setValue(false) // buyer will be informed that their offer was not accepted
                    
                    DispatchQueue.main.asyncAfter(deadline: self.when) { // wait four seconds so they can get the message, and then delete their buy request
                        buy_request.ref.removeValue()
                    }
                }
            }
        })
    }
    
    
    func listenBuyerLocation(buyer: String){
        DBProvider.Instance.buyRequestRef.queryOrdered(byChild: "seller_name").queryEqual(toValue: self.seller).observe(.value, with: { dataSnapshot in
            let enumerator = dataSnapshot.children
            while let buy_request = enumerator.nextObject() as? FIRDataSnapshot {
                let data = buy_request.value as? NSDictionary
                if (data?["name"] as? String) == buyer {
                    if let accepted = data?["accepted"] as? Bool {
                        if accepted == true {
                            self.delegate?.updateRequesterLocation(lat: data?["latitude"] as! Double, long: data?["longitude"] as! Double)
                        }
                    }
                }
            }
        })
    
        DBProvider.Instance.buyRequestRef.queryOrdered(byChild: "seller_name").queryEqual(toValue: self.seller).observe(.childChanged, with: { dataSnapshot in
            let enumerator = dataSnapshot.children
            while let buy_request = enumerator.nextObject() as? FIRDataSnapshot {
                let data = buy_request.value as? NSDictionary
                if (data?["name"] as? String) == buyer {
                    if let accepted = data?["accepted"] as? Bool {
                        if accepted == true {
                            self.delegate?.updateRequesterLocation(lat: data?["latitude"] as! Double, long: data?["longitude"] as! Double)
                        }
                    }
                }
            }
        })

    }
    
    func stopAllObservers() {
        DBProvider.Instance.buyRequestRef.removeAllObservers()
    }
    
    
    
    
}

