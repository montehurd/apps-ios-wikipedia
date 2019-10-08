
extension UIView {
    func wmf_firstSubviewOfType<T>(_ type:T.Type) -> T? {
        for subview in self.subviews {
            if subview is T {
                return subview as? T
            }
        }
        return nil
    }
    
    func wmf_firstSuperviewOfType<T>(_ type: T.Type) -> T? {
        return superview as? T ?? superview.flatMap { $0.wmf_firstSuperviewOfType(type) }
    }

    
    /*
    func printWhiteViews() {
        subviews.forEach { (v) in
            if(
                v.isHidden
                ||
                v.alpha == 0.0
                ||
                v.frame == .zero
            ){
                return
            }
            
            if let bgColor = v.backgroundColor, bgColor.wmf_hexString == "FFFFFF" {
                print("\n\nWHITE VIEW: \(v)\n\n")
            }
            
            v.printWhiteViews()
        }
    }
    */
}






/*
extension UIWindow {
    @objc func assertNoWhiteSubviews() {
        subviews.forEach { (v) in
            v.printWhiteViews()
        }
    }
}
*/


/*
@interface UIView (WhiteViews)

- (void)printWhiteViews;

@end

@implementation UIView (WhiteViews)

- (void)printWhiteViews
{

    for (UIView *subView in self.subviews) {
        if(
           subView.isHidden
           ||
           subView.alpha == 0
           ||
           (subView.frame.origin.x == 0 && subView.frame.origin.y == 0 && subView.frame.size.width == 0 && subView.frame.size.height == 0)
        ){
            return;
        }
        
        if([[subView.backgroundColor wmf_hexString] isEqualToString:@"FFFFFF"]){
            NSLog(@"\n\nWHITEVIEW = %@\n\n", subView);
        }
        
        [subView printWhiteViews];
    }
}

@end



@interface UIWindow (WhiteViews)

- (void)assertNoWhiteSubviews;

@end

@implementation UIWindow (WhiteViews)

- (void)assertNoWhiteSubviews {
    for (UIView *view in self.subviews) {
        [view printWhiteViews];
    }
}

@end


*/
