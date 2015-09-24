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
        return openURL(url)
    }
}
