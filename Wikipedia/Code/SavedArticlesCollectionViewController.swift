import UIKit
import JavaScriptCore

class SavedArticlesCollectionViewController: ReadingListEntryCollectionViewController, WKScriptMessageHandler, WKNavigationDelegate {
    
    
    
    
    
    
    
    
    
    
    
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

            print("MESSAGE RECEIVED: \(message.body)")
            
        }


    
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//            webview.evaluateJavaScript("test321()") { (result, error) in
//                print("result \(result) error \(error)")
//            }
        }

        override func didReceiveMemoryWarning() {

            
            
return
            
            
            
//            view.addSubview(webview)
            
            let htmlLocalFilePath =
                ((WikipediaAppUtils.assetsPath() as NSString)
                    .appendingPathComponent("pcs-html-converter") as NSString)
                    .appendingPathComponent("mobileview_test.html")

            let url2 = URL(fileURLWithPath: htmlLocalFilePath)
            print(url2)
            webview.loadFileURL(URL(fileURLWithPath: htmlLocalFilePath), allowingReadAccessTo: url2.deletingLastPathComponent())
            
            
            
        }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //This is not a convenience initalizer because this allows us to not inherit
    //the super class initializer, so clients can't pass any arbitrary reading list to this
    //class
    
    init?(with dataStore: MWKDataStore) {
        func fetchDefaultReadingListWithSortOrder() -> ReadingList? {
            let fetchRequest: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
            fetchRequest.fetchLimit = 1
            fetchRequest.propertiesToFetch = ["sortOrder"]
            fetchRequest.predicate = NSPredicate(format: "isDefault == YES")
            
            guard let readingLists = try? dataStore.viewContext.fetch(fetchRequest),
                let defaultReadingList = readingLists.first else {
                assertionFailure("Failed to fetch default reading list with sort order")
                return nil
            }
            return defaultReadingList
        }
        guard let readingList = fetchDefaultReadingListWithSortOrder() else {
            return nil
        }
        
        super.init(for: readingList, with: dataStore)
        emptyViewType = .noSavedPages
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var availableBatchEditToolbarActions: [BatchEditToolbarAction] {
        return [
            BatchEditToolbarActionType.addToList.action(with: nil),
            BatchEditToolbarActionType.unsave.action(with: nil)
        ]
    }
    
    override var shouldShowEditButtonsForEmptyState: Bool {
        return false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_savedPagesView())
        if !isEmpty {
            self.wmf_showLoginToSyncSavedArticlesToReadingListPanelOncePerDevice(theme: theme)
        }
    }
    
    override func shouldDelete(_ articles: [WMFArticle], completion: @escaping (Bool) -> Void) {
        let alertController = ReadingListsAlertController()
        let unsave = ReadingListsAlertActionType.unsave.action {
            completion(true)
        }
        let cancel = ReadingListsAlertActionType.cancel.action {
            completion(false)
        }
        alertController.showAlertIfNeeded(presenter: self, for: articles, with: [cancel, unsave]) { showed in
            if !showed {
                completion(true)
            }
        }
    }
    
    override func delete(_ articles: [WMFArticle]) {
        dataStore.readingListsController.unsave(articles, in: dataStore.viewContext)
        let articlesCount = articles.count
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.articleDeletedNotification(articleCount: articlesCount))
        let language = articles.count == 1 ? articles.first?.url?.wmf_language : nil
        ReadingListsFunnel.shared.logUnsaveInReadingList(articlesCount: articlesCount, language: language)
    }
    
    override func configure(cell: SavedArticlesCollectionViewCell, for entry: ReadingListEntry, at indexPath: IndexPath, layoutOnly: Bool) {
        super.configure(cell: cell, for: entry, at: indexPath, layoutOnly: layoutOnly)
        cell.delegate = self
    }
    
// hang off housekeeper and see if it runs w/o being in view herirarcy

//    lazy var webview: WKWebView = {
//        let wv = WKWebView()
//        view.addSubview(wv)
//        wv.frame = CGRect(x: 0, y: 0, width: 300, height: 800)
//        return wv
//    }()

    
    
    
    
    
    
    
    
//    func loop(times: Int) {
//        var i = 0
//
//        func nextIteration() {
//            if i < times {
//                print("i is \(i)")
//
//                i += 1
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
//                    nextIteration()
//                }
//            }
//            webview.test123()
//            print("test123")
//        }
//
//        nextIteration()
//    }

    
    
    
    
    
    
//    override func didReceiveMemoryWarning() {
        
        

//        wmf_add(childController: WebViewController2(), andConstrainToEdgesOfContainerView: view)

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
//        loop(times: 10)
     
        
//        webview.test123()
        
        
        
//        let webview2 = self.webview
//        DispatchQueue.global(qos: .background).async {
//            self.webview.evaluateJavaScript("""
//var aaa = wa => {
//    return wa
//}
//aaa('farts')
//""") { (result, error) in
//                DispatchQueue.main.async {
//                    print("result \(result) error \(error)")
//                }
//            }
//        }

        
        
        
//        guard let mobileviewToMobileHTMLConversionJSContext = JSContext() else {
//            return
//        }
        
        
        
        
        
//        let result = context.evaluateScript("""
//var aaa = wa => {
//    return `${wa} sharts`
//}
//aaa('farts')
//""")
//        print("result: \(result)") // 6

        
        
        
//        import JavaScriptCore.JSBase
//        import JavaScriptCore.JSContext
//        import JavaScriptCore.JSContextRef
//        import JavaScriptCore.JSExport
//        import JavaScriptCore.JSManagedValue
//        import JavaScriptCore.JSObjectRef
//        import JavaScriptCore.JSStringRef
//        import JavaScriptCore.JSStringRefCF
//        import JavaScriptCore.JSTypedArray
//        import JavaScriptCore.JSValue
//        import JavaScriptCore.JSValueRef
//        import JavaScriptCore.JSVirtualMachine
//        import JavaScriptCore.JavaScript
//        import JavaScriptCore.WebKitAvailability

        
        // /Users/montehurd/pcs-html-converter/PCSHTMLConverter.js
        
        // https://medium.com/swift-programming/from-swift-to-javascript-and-back-fd1f6a7a9f46

        
        
        
//        let polyfillLocalFilePath =
//            (((WikipediaAppUtils.assetsPath() as NSString)
//                .appendingPathComponent("pcs-html-converter") as NSString)
//                .appendingPathComponent("build") as NSString)
//                .appendingPathComponent("Polyfill.js")
//
//        let localFilePath =
//            (((WikipediaAppUtils.assetsPath() as NSString)
//                .appendingPathComponent("pcs-html-converter") as NSString)
//                .appendingPathComponent("build") as NSString)
//                .appendingPathComponent("PCSHTMLConverter.js")
//
//        print("path \(polyfillLocalFilePath) exists \(FileManager.default.fileExists(atPath: polyfillLocalFilePath))")
//        print("path \(localFilePath) exists \(FileManager.default.fileExists(atPath: localFilePath))")
//        /*
//        let s = try! String(contentsOfFile: localFilePath)
//
//        let p = try! String(contentsOfFile: polyfillLocalFilePath)
//        */
//
//
//        let htmlLocalFilePath =
//            ((WikipediaAppUtils.assetsPath() as NSString)
//                .appendingPathComponent("pcs-html-converter") as NSString)
//                .appendingPathComponent("mobileview_test.html")

        
        
        
        
        // mobileview_test.html
        // /Users/montehurd/wikipedia-ios/Wikipedia/assets/pcs-html-converter/mobileview_test.html
//        webview.loadFileURL(<#T##URL: URL##URL#>, allowingReadAccessTo: <#T##URL#>)
//
//
//        let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "website")!
//        webView.loadFileURL(url, allowingReadAccessTo: url)
//        let request = URLRequest(url: url)
//        webView.load(request)
        
//        let url = URL(fileURLWithPath: htmlLocalFilePath)
//        print(url)
//        webview.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        
        
        

//        var aaa = wa => {
//
//            var output = null
//            function handleMobileHTML(mobileHTML) {
//              output = mobileHTML
//              document.getElementById("mobileHTML").innerText = mobileHTML
//            }
//            let result = await PCSHTMLConverter.testMobileView().then(handleMobileHTML)
//
//            return `output = ${wa}\n${mobileHTML}`
//        }
//        aaa('farts')

        
//        webview.evaluateJavaScript("""
//        await test321()
//        """) { (result, error) in
//
//            print("result \(result) error \(error)")
//
//        }

        
        
        
        
        
        
/*
        
        var logValue = "" {
            didSet {
                print(logValue)
            }
        }
        //block we can pass to JSContext as JS function
        let showLogScript: @convention(block) (String) -> Void = { value in
            logValue = value
        }

        //set exceptionHandler block
        mobileviewToMobileHTMLConversionJSContext.exceptionHandler = {
            (ctx: JSContext!, value: JSValue!) in
            print(value)
        }
        //make showLog function available to JSContext
        mobileviewToMobileHTMLConversionJSContext.setObject(unsafeBitCast(showLogScript, to: AnyObject.self), forKeyedSubscript: "showLog" as (NSCopying & NSObjectProtocol))

        mobileviewToMobileHTMLConversionJSContext.evaluateScript(p)

        mobileviewToMobileHTMLConversionJSContext.evaluateScript(s)
        
        
        let r = mobileviewToMobileHTMLConversionJSContext.evaluateScript("PCSHTMLConverter.testMobileView()")

        
*/
        
        
        
//
//        DispatchQueue.global(qos: .background).async {
//
//            let result = mobileviewToMobileHTMLConversionJSContext.evaluateScript("""
//            var aaa = wa => {
//                return `${wa} sharts`
//            }
//            aaa('farts')
//            """)
//
//
//            DispatchQueue.main.async {
//                print("result: \(result)")
//            }
//        }
//
        
        
        
        
        
//    }
}

// MARK: - SavedArticlesCollectionViewCellDelegate

extension SavedArticlesCollectionViewController: SavedArticlesCollectionViewCellDelegate {
    func didSelect(_ tag: Tag) {
        guard let article = article(at: tag.indexPath) else {
            return
        }
        let viewController = tag.isLast ? ReadingListsViewController(with: dataStore, readingLists: article.sortedNonDefaultReadingLists) : ReadingListDetailViewController(for: tag.readingList, with: dataStore)
        viewController.apply(theme: theme)
        wmf_push(viewController, animated: true)
    }
}










/*
extension WKWebView {
    public func test123() {
        
                    
                let polyfillLocalFilePath =
                    (((WikipediaAppUtils.assetsPath() as NSString)
                        .appendingPathComponent("pcs-html-converter") as NSString)
                        .appendingPathComponent("build") as NSString)
                        .appendingPathComponent("Polyfill.js")

                let localFilePath =
                    (((WikipediaAppUtils.assetsPath() as NSString)
                        .appendingPathComponent("pcs-html-converter") as NSString)
                        .appendingPathComponent("build") as NSString)
                        .appendingPathComponent("PCSHTMLConverter.js")
                
                print("path \(polyfillLocalFilePath) exists \(FileManager.default.fileExists(atPath: polyfillLocalFilePath))")
                print("path \(localFilePath) exists \(FileManager.default.fileExists(atPath: localFilePath))")
                /*
                let s = try! String(contentsOfFile: localFilePath)

                let p = try! String(contentsOfFile: polyfillLocalFilePath)
                */
                
                
                let htmlLocalFilePath =
                    ((WikipediaAppUtils.assetsPath() as NSString)
                        .appendingPathComponent("pcs-html-converter") as NSString)
                        .appendingPathComponent("mobileview_test.html")

                
                
                
                
                // mobileview_test.html
                // /Users/montehurd/wikipedia-ios/Wikipedia/assets/pcs-html-converter/mobileview_test.html
        //        webview.loadFileURL(<#T##URL: URL##URL#>, allowingReadAccessTo: <#T##URL#>)
        //
        //
        //        let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "website")!
        //        webView.loadFileURL(url, allowingReadAccessTo: url)
        //        let request = URLRequest(url: url)
        //        webView.load(request)
                
                let url = URL(fileURLWithPath: htmlLocalFilePath)
                print(url)
                loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())

        
        
        dispatchOnMainQueueAfterDelayInSeconds(3) {
            self.evaluateJavaScript("""
                    // await document.test321()
                    "TEST ABC"
                    """) { (result, error) in
                        
                        print("result \(result) error \(error)")
                        
            }
        }


        
    }
}
*/




















// https://stackoverflow.com/a/43172313


class WebViewController2: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private var webView: WKWebView!
    private var webViewContentIsLoaded = false

    init() {
        super.init(nibName: nil, bundle: nil)

        self.webView = {
            let contentController = WKUserContentController()

            contentController.add(self, name: "WebViewControllerMessageHandler")

            let configuration = WKWebViewConfiguration()
            configuration.userContentController = contentController

            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.scrollView.bounces = false
            webView.navigationDelegate = self

            return webView
        }()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
//        view.wmf_addSubviewWithConstraintsToEdges(webView)
        
        
        view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !webViewContentIsLoaded {
            

            

            let htmlLocalFilePath =
                ((WikipediaAppUtils.assetsPath() as NSString)
                    .appendingPathComponent("pcs-html-converter") as NSString)
                    .appendingPathComponent("mobileview_test.html")

            let url2 = URL(fileURLWithPath: htmlLocalFilePath)
            print(url2)
            webView.loadFileURL(url2, allowingReadAccessTo: url2.deletingLastPathComponent())

            
            
//            let url = URL(string: "https://stackoverflow.com")!
//            let request = URLRequest(url: url)
//
//            webView.load(request)

            webViewContentIsLoaded = true
        }
    }

    private func evaluateJavascript(_ javascript: String, sourceURL: String? = nil, completion: ((_ error: Error?) -> Void)? = nil) {
        var javascript = javascript

        // Adding a sourceURL comment makes the javascript source visible when debugging the simulator via Safari in Mac OS
//        if let sourceURL = sourceURL {
//            javascript = "//# sourceURL=\(sourceURL).js\n" + javascript
//        }

        webView.evaluateJavaScript(javascript) { _, error in
            completion?(error)
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // This must be valid javascript!  Critically don't forget to terminate statements with either a newline or semicolon!

        let javascript = """
            test321()

//            var outerHTML = test321()
//            var message = {"type": "outerHTML", "outerHTML": outerHTML }
//            window.webkit.messageHandlers.WebViewControllerMessageHandler.postMessage(message)
    
"""

//        let javascript =
//        "var outerHTML = document.documentElement.outerHTML.toString()\n" +
//        "var message = {\"type\": \"outerHTML\", \"outerHTML\": outerHTML }\n" +
//        "window.webkit.messageHandlers.WebViewControllerMessageHandler.postMessage(message)\n"

        
        evaluateJavascript(javascript, sourceURL: "getOuterHMTL") { (error) in
            print("errorMessage = \(error)")
        }
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            print("could not convert message body to dictionary: \(message.body)")
            return
        }

        guard let type = body["type"] as? String else {
            print("could not convert body[\"type\"] to string: \(body)")
            return
        }

        switch type {
        case "outerHTML":
            guard let outerHTML = body["outerHTML"] as? String else {
                print("could not convert body[\"outerHTML\"] to string: \(body)")
                return
            }
            print("outerHTML is \(outerHTML)")
        default:
            print("unknown message type \(type)")
            return
        }
    }
}
