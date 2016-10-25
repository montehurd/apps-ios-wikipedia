
class WMFReferencePageBackgroundView: UIView {
    internal var clearRect:CGRect = CGRectZero
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        UIColor.clearColor().setFill()
        UIBezierPath.init(roundedRect: clearRect, cornerRadius: 3).fillWithBlendMode(.Copy, alpha: 1.0)
    }
}
