
import Foundation
import WebKit

//Responsible for listening to new NewCacheItems added to the db, fetching those urls from the network and saving the response in FileManager.

@objc public protocol ArticleCacheSyncerDBDelegate: class {
    func downloadedCacheItemFile(cacheItem: NewCacheItem)
    func deletedCacheItemFile(cacheItem: NewCacheItem)
    func failureToDeleteCacheItemFile(cacheItem: NewCacheItem, error: Error)
}

@objc(WMFArticleCacheSyncer)
final public class ArticleCacheSyncer: NSObject/*, WKScriptMessageHandler, WKNavigationDelegate*/ {
    
    private let moc: NSManagedObjectContext
    private let articleFetcher: ArticleFetcher
    private let cacheURL: URL
    private let fileManager: FileManager
    private weak var dbDelegate: ArticleCacheSyncerDBDelegate?
    
    public static let didChangeNotification = NSNotification.Name("ArticleCacheSyncerDidChangeNotification")
    public static let didChangeNotificationUserInfoDBKey = ["dbKey"]
    public static let didChangeNotificationUserInfoIsDownloadedKey = ["isDownloaded"]
    
    @objc public init(moc: NSManagedObjectContext, articleFetcher: ArticleFetcher, cacheURL: URL, fileManager: FileManager, dbDelegate: ArticleCacheSyncerDBDelegate?) {
        self.moc = moc
        self.articleFetcher = articleFetcher
        self.cacheURL = cacheURL
        self.fileManager = fileManager
        self.dbDelegate = dbDelegate
    }
    
    @objc public func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: moc)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarningNotification(note:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
    }
    
    @objc private func managedObjectContextDidSave(_ note: Notification) {
        guard let userInfo = note.userInfo else {
            assertionFailure("Expected note with userInfo dictionary")
            return
        }
        if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
            
            for item in insertedObjects {
                if let cacheItem = item as? NewCacheItem,
                cacheItem.isDownloaded == false &&
                cacheItem.isPendingDelete == false {
                    download(cacheItem: cacheItem)
                }
            }
        }
        
        if let changedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
            !changedObjects.isEmpty {
            for item in changedObjects {
                if let cacheItem = item as? NewCacheItem,
                    cacheItem.isPendingDelete == true {
                    delete(cacheItem: cacheItem)
                }
            }
        }
        
        //tonitodo: handle changed objects and deleted objects
    }
    
    func fileURL(for key: String) -> URL {
        let pathComponent = key.sha256 ?? key
        return cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
    }
    
    
    
    
    
    
    
    lazy var converter: MobileviewToMobileHTMLConverter = {
        MobileviewToMobileHTMLConverter.init()
    }()
    
    
//    lazy var bundledConverterFileURL: URL = {
//        URL(fileURLWithPath: WikipediaAppUtils.assetsPath())
//            .appendingPathComponent("pcs-html-converter", isDirectory: true)
//            .appendingPathComponent("index.html", isDirectory: false)
//    }()
    
    
    
    
    
    
    
    
    @objc public func didReceiveMemoryWarningNotification(note: Notification) {
        
        
        
guard
    let dataStore = SessionSingleton.sharedInstance()?.dataStore,
    let articleURL = URL(string: "https://en.wikipedia.org/wiki/Kodak_Tower"),
    let jsonDict = dataStore.article(with: articleURL).reconstructMobileViewJSON(imageSize: CGSize(width: 320, height: 320)),
    let mobileview = jsonDict["mobileview"] as? Dictionary<String, Any>,
    let mobileviewSections = mobileview["sections"] as? Array<Dictionary<String, Any>>
else {
    return
}
print(jsonDict)
        
        
        
        
        let mobileviewHTMLArray = mobileviewSections.map({ (s) -> String in
            return s["text"] as? String ?? ""
        })

        
        let mobileviewHTML = mobileviewHTMLArray.joined(separator: "")

        
        
        
// next step - use the lines above to get actual mobileview json string and pass it to convert instead of 123 below
// the stub convertMobileViewHTMLToMobileHTML js function i created is returning a test string - it's named wrong - is actually passed json
// string - it will need to have settings in it's meta.mw adjusted too...
//
// call "npm run -s build" if i add/changes funcs in the PCSHTMLConverter.js
// at very end will need to clear out these:
//        .git
//        .gitignore
//        .gitmodules
//        *.html (except index.html - keep that one)
//        *.json
//        node_modules
//        mobileapps

    
    
    
    
        
        converter.load {
            // get the reconstructMobileViewJSON from the saved MWKArticle -
            // https://github.com/wikimedia/wikipedia-ios/compare/develop...montehurd:mobileview-extractor#diff-94222cb464a2ffde8018b72f88281cdcR381
            self.converter.convert(url: "TEST", mobileViewHTML: "<html>123</html>") { (mobileHTML, error) in


                // TODO:
                // use the URL here to get the mobileview version of a saved article - then this will need to get passed to the JS with the url
                // may need to send the url back in the completion block
                
                
                print("mobileHTML = \(mobileHTML)")
                
            }

        }
        
//        return
            
//        webview.loadFileURL(bundledConverterFileURL, allowingReadAccessTo: bundledConverterFileURL.deletingLastPathComponent())
    }

    
    
    
    
//    lazy var webview: WKWebView = {
//        let contentController = WKUserContentController()
//
//        contentController.add(self, name: "MobileHTMLConverterMessageHandler")
//
//        let configuration = WKWebViewConfiguration()
//        configuration.userContentController = contentController
//
//        let wv = WKWebView(frame: .zero, configuration: configuration)
//
//        wv.navigationDelegate = self
//
//        return wv
//    }()
//
//    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//        guard let body = message.body as? [String: Any] else {
//            return
//        }
//        guard let urlString = body["url"] as? String else {
//            return
//        }
//        guard let mobileHTMLString = body["mobileHTML"] as? String else {
//            return
//        }
//
//        print("wa")
//    }
//
//    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        guard webView.url == bundledConverterFileURL else {
//            return
//        }
//        print("YO")
//
//
//
//
//        webview.evaluateJavaScript("convertMobileHTML('\("https://en.wikipedia.org/wiki/dog".wmf_stringBySanitizingForJavaScript())')") { (result, error) in
//            print("result \(result ?? "") error \(error?.localizedDescription ?? "")")
//        }
//    }
    
    
    
    
    
    
    
    
    
    
    
    
}


/*
 
 
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8"/>
        <script src="build/Polyfill.js"></script>
        <script src="build/PCSHTMLConverter.js"></script>
    </head>
    <body>
        <pre id="mobileHTML"></pre>
        <script>



          function handleMobileHTML(mobileHTML, url) {
            window.webkit.messageHandlers.MobileHTMLConverterMessageHandler.postMessage(
              {
                "url": url,
                "mobileHTML": mobileHTML
              }
            )
          }

         function convertMobileHTML(url) {
            let handler = mobileHTML => { return handleMobileHTML(mobileHTML, url) }
             PCSHTMLConverter.testMobileView().then(handler)
         }



         function convertMobileHTML2(url, mobileViewHTML) {
           let handler = mobileHTML => { return handleMobileHTML(mobileHTML, url) }
           PCSHTMLConverter.convertMobileViewHTMLToMobileHTML(mobileViewHTML).then(handler)
         }





        </script>
    </body>
</html>
 
 
 
 
 
async function convertMobileViewHTMLToMobileHTML(mobileViewHTML) {
    const meta = {
      domain: "en.wikipedia.org",
      baseURI: "http://localhost:6927/en.wikipedia.org/v1/",
      mw
    }
    const mobileViewJSON = JSON.parse(mobileViewHTML)
    const mobileHTML = await PCSHTMLConverter.convertMobileViewJSONToMobileHTML(mobileViewJSON, meta)
    return mobileHTML
}
*/


// WIP converter obj
class MobileviewToMobileHTMLConverter : NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    private var isConverterLoaded = false
    lazy private var completionHandlers: [String: (Any?, Error?) -> Void] = [:]
    
    public func convert(url: String, mobileViewHTML: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        guard isConverterLoaded else {
            assertionFailure("Cannot do mobile-html conversion until 'load:completionHandler:' completes")
            return
        }
        completionHandlers[url] = completionHandler
        webView.evaluateJavaScript("""
            const url = '\(url.wmf_stringBySanitizingForJavaScript())'
            const mobileViewHTML = '\(mobileViewHTML.wmf_stringBySanitizingForJavaScript())'
            convertMobileHTML2(url, mobileViewHTML)
        """) { (result, error) in
            guard error == nil else {
                self.completionHandlers.removeValue(forKey: url)
                assertionFailure("Unable to kick off mobile-html conversion \(error.debugDescription)")
                return
            }
        }
    }

    private var loadCompletionHandler: (() -> Void) = {}
    public func load(completionHandler: @escaping (() -> Void)) {
        loadCompletionHandler = completionHandler
        webView.loadFileURL(bundledConverterFileURL, allowingReadAccessTo: bundledConverterFileURL.deletingLastPathComponent())
    }
    
    lazy private var webView: WKWebView = {
        let contentController = WKUserContentController()
        
        contentController.add(self, name: "MobileHTMLConverterMessageHandler")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        
        let wv = WKWebView(frame: .zero, configuration: configuration)
        
        wv.navigationDelegate = self
        
        return wv
    }()

    lazy private var bundledConverterFileURL: URL = {
        URL(fileURLWithPath: WikipediaAppUtils.assetsPath())
            .appendingPathComponent("pcs-html-converter", isDirectory: true)
            .appendingPathComponent("index.html", isDirectory: false)
    }()

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            return
        }
        guard let url = body["url"] as? String else {
            return
        }
        guard let mobileHTMLString = body["mobileHTML"] as? String else {
            return
        }
        guard let queuedCompletionHandler = completionHandlers[url] else {
//            self.completionHandlers.removeValue(forKey: url)
            return
        }
        
        
        queuedCompletionHandler(mobileHTMLString, nil)
        
//        print(url)

        
/*
TODO:
here need to
         extact the url string and mobilehtml from the message body
         use the url string to get the correct completion handler - and invoke it with the mobilehtml
         (should the completion handlers also get passed the url? probably)
*/
        
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isConverterLoaded = true
        loadCompletionHandler()
    }

}











private extension ArticleCacheSyncer {
    func download(cacheItem: NewCacheItem) {
        
        guard let key = cacheItem.key,
            let url = URL(string: key) else {
                return
        }
        
        articleFetcher.downloadData(url: url) { (error, _, temporaryFileURL, mimeType) in
            if let _ = error {
                //tonitodo: better error handling here
                return
            }
            guard let temporaryFileURL = temporaryFileURL else {
                return
            }
            
            self.moveFile(from: temporaryFileURL, toNewFileWithKey: key, mimeType: mimeType) { (result) in
                switch result {
                case .success:
                    self.dbDelegate?.downloadedCacheItemFile(cacheItem: cacheItem)
                    NotificationCenter.default.post(name: ArticleCacheSyncer.didChangeNotification, object: nil, userInfo: [ArticleCacheSyncer.didChangeNotificationUserInfoDBKey: key,
                    ArticleCacheSyncer.didChangeNotificationUserInfoIsDownloadedKey: true])
                default:
                    //tonitodo: better error handling
                    break
                }
            }
        }
    }
    
    func delete(cacheItem: NewCacheItem) {

        guard let key = cacheItem.key else {
            assertionFailure("cacheItem has no key")
            return
        }
        
        let pathComponent = key.sha256 ?? key
        
        let cachedFileURL = self.cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
        do {
            try self.fileManager.removeItem(at: cachedFileURL)
            dbDelegate?.deletedCacheItemFile(cacheItem: cacheItem)
        } catch let error as NSError {
            if error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError {
                dbDelegate?.deletedCacheItemFile(cacheItem: cacheItem)
               NotificationCenter.default.post(name: ArticleCacheSyncer.didChangeNotification, object: nil, userInfo: [ArticleCacheSyncer.didChangeNotificationUserInfoDBKey: key,
                ArticleCacheSyncer.didChangeNotificationUserInfoIsDownloadedKey: false])
            } else {
                dbDelegate?.failureToDeleteCacheItemFile(cacheItem: cacheItem, error: error)
            }
        }
    }
    
    enum FileMoveResult {
        case exists
        case success
        case error(Error)
    }

    func moveFile(from fileURL: URL, toNewFileWithKey key: String, mimeType: String?, completion: @escaping (FileMoveResult) -> Void) {
        do {
            let newFileURL = self.fileURL(for: key)
            try self.fileManager.moveItem(at: fileURL, to: newFileURL)
            if let mimeType = mimeType {
                fileManager.setValue(mimeType, forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: newFileURL.path)
            }
            completion(.success)
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain, error.code == NSFileWriteFileExistsError {
                completion(.exists)
            } else {
                completion(.error(error))
            }
        } catch let error {
            completion(.error(error))
        }
    }

    func save(moc: NSManagedObjectContext) {
        guard moc.hasChanges else {
            return
        }
        do {
            try moc.save()
        } catch let error {
            fatalError("Error saving cache moc: \(error)")
        }
    }
}

private extension FileManager {
    func setValue(_ value: String, forExtendedFileAttributeNamed attributeName: String, forFileAtPath path: String) {
        let attributeNamePointer = (attributeName as NSString).utf8String
        let pathPointer = (path as NSString).fileSystemRepresentation
        guard let valuePointer = (value as NSString).utf8String else {
            assert(false, "unable to get value pointer from \(value)")
            return
        }

        let result = setxattr(pathPointer, attributeNamePointer, valuePointer, strlen(valuePointer), 0, 0)
        assert(result != -1)
    }
}
