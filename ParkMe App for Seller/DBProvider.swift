


import Foundation
import FirebaseDatabase

class DBProvider {

    private static let _instance = DBProvider();
    static var Instance: DBProvider{
        return _instance;
    }
    
    var dbRef: FIRDatabaseReference {
        return FIRDatabase.database().reference();
    }
    
    var requesterRef: FIRDatabaseReference {
        return dbRef.child(Constants.REQUESTER);
    }
    
    // request ref
    
    var requestRef: FIRDatabaseReference {
        return dbRef.child(Constants.PARK_REQUEST)
    }
    
    // request accepted
    
    var requestAccepted: FIRDatabaseReference {
        return dbRef.child(Constants.PARK_ACCEPTED)
    }

    func saveUser(withID: String, email: String, password: String) {
        let data: Dictionary<String, Any> = [Constants.EMAIL: email, Constants.PASSWORD: password, Constants.isRequester: true];
        
        requesterRef.child(withID).child(Constants.DATA).setValue(data);
        
    }
    
} // class
