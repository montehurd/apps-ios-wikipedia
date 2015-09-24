//  Created by Monte Hurd on 9/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

import Foundation

extension UIApplication {
    public func wmf_openURL(url: NSURL) -> Bool{
        if NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)) {
            return UIApplication.sharedApplication().openURL(url)
        }else{
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(SVModalWebViewController(URL: url), animated: true, completion: nil)
            return true;
        }
    }
}
