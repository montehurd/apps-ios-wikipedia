import Foundation

@objc class WMFDatabaseHouseKeeper : NSObject, WKScriptMessageHandler, WKNavigationDelegate {
/*
    var count = 10
    func test() {
        self.webview.evaluateJavaScript("""
    "boop"
""") { (result, error) in
            print("count = \(self.count)")
            guard result != nil, error == nil else {
                print("result = \(result ?? "") error = \(error.debugDescription)")
                return
            }
            guard self.count > 0 else {
                return
            }
            self.count = self.count - 1
            self.test()
        }
    }
    
    lazy var webview: WKWebView = {
        let wv = WKWebView()
//        view.addSubview(wv)
//        wv.frame = CGRect(x: 0, y: 0, width: 300, height: 800)
        return wv
    }()

    @objc func test123() {
        
        
        //loop(times: 10)
        
        test()
        
        
        
//        webview.test123()
        
        
//        print("test123")

    }
     
     
     
     let contentController = WKUserContentController()

     contentController.add(self, name: "WebViewControllerMessageHandler")

     let configuration = WKWebViewConfiguration()
     configuration.userContentController = contentController

     let webView = WKWebView(frame: .zero, configuration: configuration)

*/    
    

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
            lazy var webview: WKWebView = {
                let contentController = WKUserContentController()

                contentController.add(self, name: "WebViewControllerMessageHandler")

                let configuration = WKWebViewConfiguration()
                configuration.userContentController = contentController

                let wv = WKWebView(frame: .zero, configuration: configuration)

    //            let wv = WKWebView()
                wv.navigationDelegate = self


                return wv
            }()

            

            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                print("\n ---------- \nMESSAGE RECEIVED: \(message.body) \n processed \(Date()) \n itemsToProcessCounter \(itemsToProcessCounter) time remaining \(UIApplication.shared.backgroundTimeRemaining)")

                
                itemsToProcessCounter = itemsToProcessCounter - 1
                
                if (itemsToProcessCounter == 0) {
                    
                    webview.evaluateJavaScript("stop123()") { (result, error) in
                        print("result \(result) error \(error)")
                    }

                    
                    completionHandler("TOTAL SUCCESS", nil)
                }

                
            }


        
            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    //            webview.evaluateJavaScript("test321()") { (result, error) in
    //                print("result \(result) error \(error)")
    //            }
            }

    
    
    /*
     PER JOE:
     - for ios integration just grab build products and directly check those in - have note about steps to regen these, but don't spend time on scripty bits
     - figure out if when app backgrounded if the code native code which processes messages is still happening...
     */
    
    var completionHandler: ((Any?, Error?) -> Void) = {(result, error) in }
    var itemsToProcessCounter = 100

    @objc func stopKickingIt(completionHandler:  ((Any?, Error?) -> Void)? = nil) {
        webview.evaluateJavaScript("stop123()", completionHandler: completionHandler)
    }
    
    @objc func kickIt(completionHandler: @escaping ((Any?, Error?) -> Void)) {
//    @objc func kickIt() {
//        let wv = webview
        
        //view.addSubview(webview)
        
        let htmlLocalFilePath =
            ((WikipediaAppUtils.assetsPath() as NSString)
                .appendingPathComponent("pcs-html-converter") as NSString)
                .appendingPathComponent("mobileview_test.html")

        let url2 = URL(fileURLWithPath: htmlLocalFilePath)
        print(url2)
self.completionHandler = completionHandler
        webview.loadFileURL(URL(fileURLWithPath: htmlLocalFilePath), allowingReadAccessTo: url2.deletingLastPathComponent())

    }
    
    
    
    
    
    // Returns deleted URLs
    @objc func performHouseKeepingOnManagedObjectContext(_ moc: NSManagedObjectContext, navigationStateController: NavigationStateController) throws -> [URL] {
        
        let urls = try deleteStaleUnreferencedArticles(moc, navigationStateController: navigationStateController)

        try deleteStaleTalkPages(moc)

        return urls
    }

    // Returns articles to remove from disk
    @objc func articleURLsToRemoveFromDiskInManagedObjectContext(_ moc: NSManagedObjectContext, navigationStateController: NavigationStateController) throws -> [URL] {
        guard let preservedArticleKeys = navigationStateController.allPreservedArticleKeys(in: moc) else {
            return []
        }
        
        let articlesToRemoveFromDiskPredicate = NSPredicate(format: "isCached == TRUE && savedDate == NULL && !(key IN %@)", preservedArticleKeys)
        let articlesToRemoveFromDiskFetchRequest = WMFArticle.fetchRequest()
        articlesToRemoveFromDiskFetchRequest.predicate = articlesToRemoveFromDiskPredicate
        let articlesToRemoveFromDisk = try moc.fetch(articlesToRemoveFromDiskFetchRequest)
        
        for article in articlesToRemoveFromDisk {
            article.isCached = false
        }
        
        if (moc.hasChanges) {
            try moc.save()
        }
        
        return articlesToRemoveFromDisk.compactMap { $0.url }
    }

    /**
     
     We only persist the last 50 most recently accessed talk pages, delete all others.
     
    */
    private func deleteStaleTalkPages(_ moc: NSManagedObjectContext) throws {
        let request: NSFetchRequest<NSFetchRequestResult> = TalkPage.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateAccessed", ascending: false)]
        request.fetchOffset = 50
        let batchRequest = NSBatchDeleteRequest(fetchRequest: request)
        batchRequest.resultType = .resultTypeObjectIDs
        
        let result = try moc.execute(batchRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes: [AnyHashable : Any] = [NSDeletedObjectsKey : objectIDArray as Any]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [moc])
        
        try moc.removeUnlinkedTalkPageTopicContent()
    }
    
    private func deleteStaleUnreferencedArticles(_ moc: NSManagedObjectContext, navigationStateController: NavigationStateController) throws -> [URL] {
        
        /**
 
        Find `WMFContentGroup`s more than WMFExploreFeedMaximumNumberOfDays days old.
 
        */
        
        let today = Date() as NSDate
        guard let oldestFeedDateMidnightUTC = today.wmf_midnightUTCDateFromLocalDate(byAddingDays: 0 - WMFExploreFeedMaximumNumberOfDays) else {
            assertionFailure("Calculating midnight UTC on the oldest feed date failed")
            return []
        }
        
        let allContentGroupFetchRequest = WMFContentGroup.fetchRequest()
        
        let allContentGroups = try moc.fetch(allContentGroupFetchRequest)
        var referencedArticleKeys = Set<String>(minimumCapacity: allContentGroups.count * 5 + 1)
        
        for group in allContentGroups {
            if group.midnightUTCDate?.compare(oldestFeedDateMidnightUTC) == .orderedAscending {
                moc.delete(group)
                continue
            }
            
            if let articleURLDatabaseKey = group.articleURL?.wmf_databaseKey {
                referencedArticleKeys.insert(articleURLDatabaseKey)
            }

            if let previewURL = group.contentPreview as? NSURL, let key = previewURL.wmf_databaseKey {
                referencedArticleKeys.insert(key)
            }

            guard let fullContent = group.fullContent else {
                continue
            }

            guard let content = fullContent.object as? [Any] else {
                assertionFailure("Unknown Content Type")
                continue
            }
            
            for obj in content {
                
                switch (group.contentType, obj) {
                    
                case (.URL, let url as NSURL):
                    guard let key = url.wmf_databaseKey else {
                        continue
                    }
                    referencedArticleKeys.insert(key)
                    
                case (.topReadPreview, let preview as WMFFeedTopReadArticlePreview):
                    guard let key = (preview.articleURL as NSURL).wmf_databaseKey else {
                        continue
                    }
                    referencedArticleKeys.insert(key)
                    
                case (.story, let story as WMFFeedNewsStory):
                    guard let articlePreviews = story.articlePreviews else {
                        continue
                    }
                    for preview in articlePreviews {
                        guard let key = (preview.articleURL as NSURL).wmf_databaseKey else {
                            continue
                        }
                        referencedArticleKeys.insert(key)
                    }
                    
                case (.URL, _),
                     (.topReadPreview, _),
                     (.story, _),
                     (.image, _),
                     (.notification, _),
                     (.announcement, _),
                     (.onThisDayEvent, _),
                     (.theme, _):
                    break
                    
                default:
                    assertionFailure("Unknown Content Type")
                }
            }
        }
      
        /** 
  
        Find WMFArticles that are cached previews only, and have no user-defined state.
 
            - A `viewedDate` of null indicates that the article was never viewed
            - A `savedDate` of null indicates that the article is not saved
            - A `placesSortOrder` of null indicates it is not currently visible on the Places map
            - Items with `isExcludedFromFeed == YES` need to stay in the database so that they will continue to be excluded from the feed
        */
        
        let articlesToDeleteFetchRequest = WMFArticle.fetchRequest()
        var articlesToDeletePredicate = NSPredicate(format: "viewedDate == NULL && savedDate == NULL && placesSortOrder == 0 && isExcludedFromFeed == FALSE")
        
        if let preservedArticleKeys = navigationStateController.allPreservedArticleKeys(in: moc) {
            referencedArticleKeys.formUnion(preservedArticleKeys)
        }
        
        if !referencedArticleKeys.isEmpty {
            let referencedKeysPredicate = NSPredicate(format: "!(key IN %@)", referencedArticleKeys)
            articlesToDeletePredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[articlesToDeletePredicate,referencedKeysPredicate])
        }

        articlesToDeleteFetchRequest.predicate = articlesToDeletePredicate

        let articlesToDelete = try moc.fetch(articlesToDeleteFetchRequest)
        
        var urls: [URL] = []
        for obj in articlesToDelete {
            guard obj.isFault else { // only delete articles that are faults. prevents deletion of articles that are being actively viewed. repro steps: open disambiguation pages view -> exit app -> re-enter app
                continue
            }
            moc.delete(obj)
            guard let url = obj.url else {
                continue
            }
            urls.append(url)
        }
        
        
        if (moc.hasChanges) {
            try moc.save()
        }
        
        return urls
    }
}
