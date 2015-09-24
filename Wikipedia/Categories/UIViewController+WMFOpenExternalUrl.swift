//  Created by Monte Hurd on 9/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

import Foundation

extension UIViewController {
    public func wmf_openExternalUrl(url: NSURL){
        if NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)) {
            UIApplication.sharedApplication().openURL(url)
        }else{
            let presentInModal = {self.presentViewController(SVModalWebViewController(URL: url), animated: true, completion: nil)}
            if (self.presentedViewController != nil){
                self.dismissViewControllerAnimated(true, completion: {
                    presentInModal()
                })
                return;
            }
            presentInModal()
        }
    }
}
