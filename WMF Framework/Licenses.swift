import Foundation

@objc(WMFLicenses)
class Licenses: NSObject {
    static let localizedCCBYSA3Title = WMFLocalizedString("cc-by-sa-3.0", value: "CC BY-SA 3.0", comment: "Name of the CC BY-SA 3.0 license - https://creativecommons.org/licenses/by-sa/3.0/")
    static let localizedGDFLTitle = WMFLocalizedString("gdfl", value: "GDFL", comment: "Name of the GDFL license - https://www.gnu.org/licenses/fdl.html")
    static let localizedSaveTermsTitle = WMFLocalizedString("wikitext-upload-save-terms-name", value: "Terms of Use", comment: "This message is used in the message [[Wikimedia:Wikipedia-ios-wikitext-upload-save-terms-and-license]].")

   
    static let CCBYSA3URL = URL(string: "https://creativecommons.org/licenses/by-sa/3.0/")
    static let GDFLURL = URL(string: "https://www.gnu.org/licenses/fdl.html")
    static let saveTermsURL = URL(string:"https://wikimediafoundation.org/wiki/Terms_of_Use")
}

