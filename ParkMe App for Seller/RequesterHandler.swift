

import Foundation
import FirebaseDatabase

class RequesterHandler {
    static let _instance = RequesterHandler();
    
    var requester = "";
    var requester_id = "";
    
    
    static var Instance: RequesterHandler {
        return _instance;
    }
    
    
    
}
