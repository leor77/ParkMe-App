


import Foundation
import FirebaseDatabase
import FirebaseAuth

class DBProvider {

    private static let _instance = DBProvider();
    static var Instance: DBProvider{
        return _instance;
    }
    
    let user = FIRAuth.auth()?.currentUser

    
    var dbRef: FIRDatabaseReference {
        return FIRDatabase.database().reference();
    }
    
    var sellerRef: FIRDatabaseReference {
        return dbRef.child(Constants.SELLER);
    }
    
    var userRef: FIRDatabaseReference {
        return dbRef.child(Constants.USER);
    }
    
    // seller ref
    
    var sellRequestRef: FIRDatabaseReference {
        return dbRef.child(Constants.SELL_REQUEST)
    }
    
    // buy request ref
    
    var buyRequestRef: FIRDatabaseReference {
        return dbRef.child(Constants.BUY_REQUEST)
    }
    
    // request accepted
    
    var requestAccepted: FIRDatabaseReference {
        return dbRef.child(Constants.PARK_ACCEPTED)
    }

    func saveUser(withID: String, email: String, password: String) {
        let data: Dictionary<String, Any> = [Constants.EMAIL: email, Constants.PASSWORD: password];
        
        userRef.child(withID).child(Constants.DATA).setValue(data); // save user to DB
        
    }
    
} // class
