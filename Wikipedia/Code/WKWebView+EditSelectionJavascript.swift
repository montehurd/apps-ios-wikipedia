
import WebKit

extension WKWebView {
    private func selectedTextEditInfo(from dictionary: Dictionary<String, Any>) -> SelectedTextEditInfo? {
        guard
            let selectedAndAdjacentTextDict = dictionary["selectedAndAdjacentText"] as? Dictionary<String, Any>,
            let selectedText = selectedAndAdjacentTextDict["selectedText"] as? String,
            let textBeforeSelectedText = selectedAndAdjacentTextDict["textBeforeSelectedText"] as? String,
            let textAfterSelectedText = selectedAndAdjacentTextDict["textAfterSelectedText"] as? String,
            let isSelectedTextInTitleDescription = dictionary["isSelectedTextInTitleDescription"] as? Bool,
            let sectionID = dictionary["sectionID"] as? Int
            else {
                DDLogError("Error converting dictionary to SelectedTextEditInfo")
                return nil
        }
        let selectedAndAdjacentText = SelectedAndAdjacentText(selectedText: selectedText, textAfterSelectedText: textAfterSelectedText, textBeforeSelectedText: textBeforeSelectedText)
        return SelectedTextEditInfo(selectedAndAdjacentText: selectedAndAdjacentText, isSelectedTextInTitleDescription: isSelectedTextInTitleDescription, sectionID: sectionID)
    }
    
    @objc func wmf_getSelectedTextEditInfo(completionHandler: ((SelectedTextEditInfo?, Error?) -> Void)? = nil) {
        evaluateJavaScript("window.wmf.editTextSelection.getSelectedTextEditInfo()") { (result, error) in
            guard let error = error else {
                guard let completionHandler = completionHandler else {
                    return
                }
                guard
                    let resultDict = result as? Dictionary<String, Any>,
                    let selectedTextEditInfo = self.selectedTextEditInfo(from: resultDict)
                else {
                    DDLogError("Error handling 'getSelectedTextEditInfo()' dictionary response")
                    return
                }
                
                completionHandler(selectedTextEditInfo, nil)
                return
            }
            DDLogError("Error when evaluating javascript on fetch and transform: \(error)")
        }
    }
}

@objcMembers class SelectedAndAdjacentText: NSObject  {
    public let selectedText: String
    public let textAfterSelectedText: String
    public let textBeforeSelectedText: String
    init(selectedText: String, textAfterSelectedText: String, textBeforeSelectedText: String) {
        self.selectedText = selectedText
        self.textAfterSelectedText = textAfterSelectedText
        self.textBeforeSelectedText = textBeforeSelectedText
    }
}

@objcMembers class SelectedTextEditInfo: NSObject {
    public let selectedAndAdjacentText: SelectedAndAdjacentText
    public let isSelectedTextInTitleDescription: Bool
    public let sectionID: Int
    init(selectedAndAdjacentText: SelectedAndAdjacentText, isSelectedTextInTitleDescription: Bool, sectionID: Int) {
        self.selectedAndAdjacentText = selectedAndAdjacentText
        self.isSelectedTextInTitleDescription = isSelectedTextInTitleDescription
        self.sectionID = sectionID
    }
}
