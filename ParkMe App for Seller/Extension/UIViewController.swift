
import UIKit

extension UIViewController {
    func presentAlert(title: String, message : String?, cancelTapped: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: cancelTapped)
        alertController.addAction(OKAction)

        present(alertController, animated: true, completion: nil)
    }
}
