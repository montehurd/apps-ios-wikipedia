/*
 Enables a subclass which uses a xib to iself be easily used inside another storyboard/xib.
 Makes composition easier.
*/
class ViewFromNib: UIView {
    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        guard subviews.count == 0, let viewFromNib = type(of:self).wmf_viewFromClassNib() else {
            return self
        }
        return viewFromNib
    }
}
