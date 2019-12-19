
fileprivate extension MWKSection {
    func mobileViewDict() -> [String: Any?] {
        var dict: [String: Any?] = [:]
        dict["toclevel"] = toclevel
        dict["level"] = level?.stringValue
        dict["line"] = line
        dict["number"] = number
        dict["index"] = index
        dict["anchor"] = anchor
        dict["id"] = sectionId
        dict["text"] = "text" // stringByReplacingImageURLsWithAppSchemeURLs(inHTMLString: text ?? "", withBaseURL: baseURL, targetImageWidth: imageWidth)
        dict["fromtitle"] = fromURL?.wmf_titleWithUnderscores
        return dict
    }
}

fileprivate extension MWKArticle {
    func mobileViewLastModified() -> String? {
        if let lastModifiedDate = lastmodified {
            return iso8601DateString(lastModifiedDate)
        }
        return nil
    }
    func mobileViewLastModifiedBy() -> [String: String]? {
        if let lastmodifiedby = lastmodifiedby {
            return [
                "name": lastmodifiedby.name ?? "",
                "gender": lastmodifiedby.gender ?? ""
            ]
        }
        return nil
    }
    func mobileViewPageProps() -> [String: String]? {
        if let wikidataId = wikidataId {
            return [
                "wikibase_item": wikidataId
            ]
        }
        return nil
    }
    func mobileViewDescriptionSource() -> String? {
        switch descriptionSource {
        case .local:
            return "local"
        case .central:
            return "central"
        default:
            // should default use "local" too?
            return nil
        }
    }
    func mobileViewImage(size: CGSize) -> [String: Any]? {
        if let imgName = image?.canonicalFilename() {
            return [
                "file": imgName,
                "width": size.width,
                "height": size.height
            ]
        }
        return nil
    }
    func mobileViewThumbnail() -> [String: Any]? {
        if let thumbnailSourceURL = imageURL /*article.thumbnail?.sourceURL.absoluteString*/ {
            return [
                "url": thumbnailSourceURL
                // Can't seem to find the original thumb "width" and "height" to match that seen in the orig mobileview - did we not save/model these?
            ]
        }
        return nil
    }
    func mobileViewProtection() -> [String: Any]? {
        if let protection = protection {
            var protectionDict:[String: Any] = [:]
            for protectedAction in protection.protectedActions() {
                guard let actionString = protectedAction as? String else {
                    continue
                }
                protectionDict[actionString] = protection.allowedGroups(forAction: actionString)
            }
            return protectionDict
        }
        return nil
    }
    // ^ switch these to use guard
}

extension WMFArticleJSONCompilationHelper {
    @objc static func reconstructMobileViewJSON(for url: URL, from dataStore: MWKDataStore, imageSize: CGSize) -> Data? {
        let article = dataStore.article(with: url)
        /*
        print("""
        
            MWK ARTICLE:
            \(article)
            
        """)
        */
        guard
            let sections = article.sections?.entries as? [MWKSection]
        else {
            assertionFailure("Couldn't get expected article sections")
            return nil
        }

        var mvDict: [String: Any] = [:]
        
        mvDict["ns"] = article.ns
        mvDict["lastmodified"] = article.mobileViewLastModified()
        mvDict["lastmodifiedby"] = article.mobileViewLastModifiedBy()
        mvDict["revision"] = article.revisionId
        mvDict["languagecount"] = article.languagecount
        mvDict["displaytitle"] = article.displaytitle
        mvDict["id"] = article.articleId
        mvDict["pageprops"] = article.mobileViewPageProps()
        mvDict["description"] = article.entityDescription
        mvDict["descriptionsource"] = article.mobileViewDescriptionSource()
        mvDict["sections"] = sections.map { $0.mobileViewDict() }
        mvDict["editable"] = article.editable
        mvDict["image"] = article.mobileViewImage(size: imageSize)
        mvDict["thumb"] = article.mobileViewThumbnail()
        mvDict["protection"] = article.mobileViewProtection()
        
        return try? JSONSerialization.data(withJSONObject: ["mobileview": mvDict], options: [.prettyPrinted])
    }
}
