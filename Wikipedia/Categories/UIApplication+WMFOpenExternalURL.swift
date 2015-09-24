//
//  UIApplication+WMFOpenExternalURL.swift
//  Wikipedia
//
//  Created by Monte Hurd on 9/24/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

extension UIApplication {
    public func wmf_openURL(url: NSURL) -> Bool {
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(SVModalWebViewController(URL: url), animated: true, completion: nil)
        return true;
    }
}
