
import Foundation

public class MyTimer {

    static let shared = MyTimer()

    var startTimes = [String : Date]()

    func start(withKey key: String) {
        startTimes[key] = Date()
    }

    func measure(key: String) -> TimeInterval? {
        if let start = startTimes[key] {
            return Date().timeIntervalSince(start)
        }

        return nil
    }

}
