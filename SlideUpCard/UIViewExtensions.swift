import UIKit

extension UIView {
    @IBInspectable var borderColor: UIColor? {
        get {
            layer.borderColor == nil ? nil : UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}
