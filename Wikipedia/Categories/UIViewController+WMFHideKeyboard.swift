import Foundation

extension UIViewController {
    func wmf_hideKeyboard () {
        //http://stackoverflow.com/questions/11879745/an-utility-method-for-hiding-the-keyboard
        UIApplication.sharedApplication().sendAction("resignFirstResponder", to: nil, from: nil, forEvent: nil)
    }
}
