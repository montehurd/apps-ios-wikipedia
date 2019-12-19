
extension MWKSection {
    fileprivate func mobileViewDict() -> [String: Any?] {
        var dict: [String: Any?] = [:]
        dict["toclevel"] = toclevel
        dict["level"] = level?.stringValue
        dict["line"] = line
        dict["number"] = number
        dict["index"] = index
        dict["anchor"] = anchor
        dict["id"] = sectionId
        dict["text"] = text // stringByReplacingImageURLsWithAppSchemeURLs(inHTMLString: text ?? "", withBaseURL: baseURL, targetImageWidth: imageWidth)
        dict["fromtitle"] = fromURL?.wmf_titleWithUnderscores
        return dict
    }
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
        if let lastModifiedDate = article.lastmodified {
            mvDict["lastmodified"] = article.iso8601DateString(lastModifiedDate)
        }
        if let lastmodifiedby = article.lastmodifiedby {
            let lastmodifiedbyDict:[String: String] = [
                "name": lastmodifiedby.name ?? "",
                "gender": lastmodifiedby.gender ?? ""
            ]
            mvDict["lastmodifiedby"] = lastmodifiedbyDict
        }
        
        mvDict["revision"] = article.revisionId
        mvDict["languagecount"] = article.languagecount
        mvDict["displaytitle"] = article.displaytitle
        mvDict["id"] = article.articleId
        
        if let wikidataId = article.wikidataId {
            let pagePropsDict:[String: String] = [
                "wikibase_item": wikidataId
            ]
            mvDict["pageprops"] = pagePropsDict
        }
        
        mvDict["description"] = article.entityDescription
        
        switch article.descriptionSource {
        case .local:
            mvDict["descriptionsource"] = "local"
        case .central:
            mvDict["descriptionsource"] = "central"
        default:
            // should default use "local" too?
            break
        }
        
        mvDict["sections"] = sections.map { (section) -> [String: Any?] in
            section.mobileViewDict()
        }
        
        mvDict["editable"] = article.editable

        if let imgName = article.image?.canonicalFilename() {
            let imageDict:[String: Any] = [
                "file": imgName,
                "width": imageSize.width,
                "height": imageSize.height
            ]
            mvDict["image"] = imageDict
        }

        if let thumbnailSourceURL = article.imageURL /*article.thumbnail?.sourceURL.absoluteString*/ {
            let thumbnailDict:[String: Any] = [
                "url": thumbnailSourceURL
                // Can't seem to find the original thumb "width" and "height" to match that seen in the orig mobileview - did we not save/model these?
            ]
            mvDict["thumb"] = thumbnailDict
        }

        if let protection = article.protection {
            var protectionDict:[String: Any] = [:]
            for protectedAction in protection.protectedActions() {
                guard let actionString = protectedAction as? String else {
                    continue
                }
                protectionDict[actionString] = protection.allowedGroups(forAction: actionString)
            }
            mvDict["protection"] = protectionDict
        }
        
        return try? JSONSerialization.data(withJSONObject: ["mobileview": mvDict], options: [.prettyPrinted])
    }
}
