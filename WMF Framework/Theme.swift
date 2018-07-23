import Foundation

public extension UIColor {
    @objc public convenience init(_ hex: Int, alpha: CGFloat) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    @objc(initWithHexInteger:)
    public convenience init(_ hex: Int) {
        self.init(hex, alpha: 1)
    }
    
    @objc public class func wmf_colorWithHex(_ hex: Int) -> UIColor {
        return UIColor(hex)
    }

    fileprivate static let defaultShadow = UIColor(white: 0, alpha: 0.25)

    fileprivate static let pitchBlack = UIColor(0x101418)

    fileprivate static let base10 = UIColor(0x222222)
    fileprivate static let base20 = UIColor(0x54595D)
    fileprivate static let base30 = UIColor(0x72777D)
    fileprivate static let base50 = UIColor(0xA2A9B1)
    fileprivate static let base70 = UIColor(0xC8CCD1)
    fileprivate static let base80 = UIColor(0xEAECF0)
    fileprivate static let base90 = UIColor(0xF8F9FA)
    fileprivate static let base100 = UIColor(0xFFFFFF)
    fileprivate static let red30 = UIColor(0xB32424)
    fileprivate static let red50 = UIColor(0xCC3333)
    fileprivate static let red75 = UIColor(0xFF6E6E)
    fileprivate static let yellow50 = UIColor(0xFFCC33)
    fileprivate static let green50 = UIColor(0x00AF89)
    fileprivate static let blue10 = UIColor(0x2A4B8D)
    fileprivate static let blue50 = UIColor(0x3366CC)
    fileprivate static let lightBlue = UIColor(0xEAF3FF)
    fileprivate static let mesosphere = UIColor(0x43464A)
    fileprivate static let thermosphere = UIColor(0x2E3136)
    fileprivate static let stratosphere = UIColor(0x6699FF)
    fileprivate static let exosphere = UIColor(0x27292D)
    fileprivate static let accent = UIColor(0x00AF89)
    fileprivate static let accent10 = UIColor(0x2A4B8D)
    fileprivate static let amate = UIColor(0xE1DAD1)
    fileprivate static let parchment = UIColor(0xF8F1E3)
    fileprivate static let masi = UIColor(0x646059)
    fileprivate static let papyrus = UIColor(0xF0E6D6)
    fileprivate static let kraft = UIColor(0xCBC8C1)
    fileprivate static let osage = UIColor(0xFF9500)
    fileprivate static let sand = UIColor(0xE8DCCA)
    
    fileprivate static let darkSearchFieldBackground = UIColor(0x8E8E93, alpha: 0.12)
    fileprivate static let lightSearchFieldBackground = UIColor(0xFFFFFF, alpha: 0.15)

    fileprivate static let masi60PercentAlpha = UIColor(0x646059, alpha:0.6)
    fileprivate static let black50PercentAlpha = UIColor(0x000000, alpha:0.5)
    fileprivate static let black75PercentAlpha = UIColor(0x000000, alpha:0.75)
    fileprivate static let white20PercentAlpha = UIColor(white: 1, alpha:0.2)

    fileprivate static let base70At55PercentAlpha = base70.withAlphaComponent(0.55)
    fileprivate static let blue50At10PercentAlpha = UIColor(0x3366CC, alpha:0.1)
    fileprivate static let blue50At25PercentAlpha = UIColor(0x3366CC, alpha:0.25)

    @objc public static let wmf_darkGray = UIColor(0x4D4D4B)
    @objc public static let wmf_lightGray = UIColor(0x9AA0A7)
    @objc public static let wmf_gray = UIColor.base70
    @objc public static let wmf_lighterGray = UIColor.base80
    @objc public static let wmf_lightestGray = UIColor(0xF5F5F5) // also known as refresh gray

    @objc public static let wmf_darkBlue = UIColor.blue10
    @objc public static let wmf_blue = UIColor.blue50
    @objc public static let wmf_lightBlue = UIColor.lightBlue

    @objc public static let wmf_green = UIColor.green50
    @objc public static let wmf_lightGreen = UIColor(0xD5FDF4)

    @objc public static let wmf_red = UIColor.red50
    @objc public static let wmf_lightRed = UIColor(0xFFE7E6)
    
    @objc public static let wmf_yellow = UIColor.yellow50
    @objc public static let wmf_lightYellow = UIColor(0xFEF6E7)
    
    @objc public static let wmf_orange = UIColor(0xFF5B00)
    
    @objc public static let wmf_purple = UIColor(0x7F4AB3)
    @objc public static let wmf_lightPurple = UIColor(0xF3E6FF)

    @objc public func wmf_hexStringIncludingAlpha(_ includeAlpha: Bool) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        var hexString = String(format: "%02X%02X%02X", Int(255.0 * r), Int(255.0 * g), Int(255.0 * b))
        if (includeAlpha) {
            hexString = hexString.appendingFormat("%02X", Int(255.0 * a))
        }
        return hexString
    }
    
    @objc public var wmf_hexString: String {
        return wmf_hexStringIncludingAlpha(false)
    }
}

@objc(WMFColors)
public class Colors: NSObject {
    fileprivate static let light = Colors(baseBackground: .base80, midBackground: .base90, paperBackground: .base100, chromeBackground: .base100,  popoverBackground: .base100, subCellBackground: .base100, overlayBackground: .black50PercentAlpha, batchSelectionBackground: .lightBlue, referenceHighlightBackground: .clear, hintBackground: .lightBlue, overlayText: .base20, searchFieldBackground: .darkSearchFieldBackground, keyboardBarSearchFieldBackground: .base80, primaryText: .base10, secondaryText: .base30, tertiaryText: .base70, disabledText: .base80, disabledLink: .lightBlue, chromeText: .base20, link: .blue50, accent: .green50, border: .base80, shadow: .base80, chromeShadow: .defaultShadow, cardBackground: .base100, cardBorder: .base100, cardShadow: .base10, cardButtonBackground: .wmf_lightestGray, secondaryAction: .blue10, icon: nil, iconBackground: nil, destructive: .red50, error: .red50, warning: .osage, unselected: .base50, blurEffectStyle: .extraLight, blurEffectBackground: .clear, tagText: .blue50, tagBackground: .blue50At10PercentAlpha, tagSelectedBackground: .blue50At25PercentAlpha)

    fileprivate static let sepia = Colors(baseBackground: .amate, midBackground: .papyrus, paperBackground: .parchment, chromeBackground: .parchment, popoverBackground: .base100, subCellBackground: .papyrus, overlayBackground: .masi60PercentAlpha, batchSelectionBackground: .lightBlue, referenceHighlightBackground: .clear, hintBackground: .lightBlue, overlayText: .base20, searchFieldBackground: .darkSearchFieldBackground, keyboardBarSearchFieldBackground: .base80, primaryText: .base10, secondaryText: .masi, tertiaryText: .masi, disabledText: .base80, disabledLink: .lightBlue, chromeText: .base20, link: .blue50, accent: .green50, border: .kraft, shadow: .kraft,  chromeShadow: .base20, cardBackground: .papyrus, cardBorder: .sand, cardShadow: .clear, cardButtonBackground: .amate, secondaryAction: .accent10, icon: .masi, iconBackground: .amate, destructive: .red30, error: .red30, warning: .osage, unselected: .masi, blurEffectStyle: .extraLight, blurEffectBackground: .clear, tagText: .base100, tagBackground: .stratosphere, tagSelectedBackground: .blue50)
    
    fileprivate static let dark = Colors(baseBackground: .base10, midBackground: .exosphere, paperBackground: .thermosphere, chromeBackground: .mesosphere, popoverBackground: .base10, subCellBackground: .exosphere, overlayBackground: .black75PercentAlpha, batchSelectionBackground: .accent10, referenceHighlightBackground: .clear, hintBackground: .pitchBlack, overlayText: .base20, searchFieldBackground: .lightSearchFieldBackground, keyboardBarSearchFieldBackground: .thermosphere, primaryText: .base90, secondaryText: .base70, tertiaryText: .base70, disabledText: .base70, disabledLink: .lightBlue, chromeText: .base90, link: .stratosphere, accent: .green50, border: .mesosphere, shadow: .base10, chromeShadow: .base10, cardBackground: .exosphere, cardBorder: .thermosphere, cardShadow: .clear, cardButtonBackground: .mesosphere, secondaryAction: .accent10, icon: .base70, iconBackground: .exosphere, destructive: .red75, error: .red75, warning: .yellow50, unselected: .base70, blurEffectStyle: .dark, blurEffectBackground: .base70At55PercentAlpha, tagText: .base100, tagBackground: .stratosphere, tagSelectedBackground: .blue50)

    fileprivate static let black = Colors(baseBackground: .pitchBlack, midBackground: .base10, paperBackground: .black, chromeBackground: .base10, popoverBackground: .base10, subCellBackground: .base10, overlayBackground: .black75PercentAlpha, batchSelectionBackground: .accent10, referenceHighlightBackground: .white20PercentAlpha, hintBackground: .thermosphere, overlayText: .base20, searchFieldBackground: .lightSearchFieldBackground, keyboardBarSearchFieldBackground: .thermosphere, primaryText: .base90, secondaryText: .base70, tertiaryText: .base70, disabledText: .base70, disabledLink: .lightBlue, chromeText: .base90, link: .stratosphere, accent: .green50, border: .mesosphere, shadow: .base10, chromeShadow: .base10, cardBackground: .base10, cardBorder: .exosphere, cardShadow: .clear, cardButtonBackground: .thermosphere, secondaryAction: .accent10, icon: .base70, iconBackground: .exosphere, destructive: .red75, error: .red75, warning: .yellow50, unselected: .base70, blurEffectStyle: .dark, blurEffectBackground: .base70At55PercentAlpha, tagText: .base100, tagBackground: .stratosphere, tagSelectedBackground: .blue50)
    
    fileprivate static let widget = Colors(baseBackground: .clear, midBackground: .clear, paperBackground: .clear, chromeBackground: .clear,  popoverBackground: .clear, subCellBackground: .clear, overlayBackground: UIColor(white: 1.0, alpha: 0.4), batchSelectionBackground: .lightBlue, referenceHighlightBackground: .clear, hintBackground: .clear, overlayText: .base20, searchFieldBackground: .lightSearchFieldBackground, keyboardBarSearchFieldBackground: .base80, primaryText: .base10, secondaryText: .base10, tertiaryText: .base20, disabledText: .base30, disabledLink: .lightBlue, chromeText: .base20, link: .accent10, accent: .green50, border: UIColor(white: 0, alpha: 0.15) , shadow: .base80, chromeShadow: .base80, cardBackground: .black, cardBorder: .clear, cardShadow: .black, cardButtonBackground: .black, secondaryAction: .blue10, icon: nil, iconBackground: nil, destructive: .red50, error: .red50, warning: .yellow50, unselected: .base50, blurEffectStyle: .extraLight, blurEffectBackground: .clear, tagText: .clear, tagBackground: .clear, tagSelectedBackground: .clear)
    
    @objc public let baseBackground: UIColor
    @objc public let midBackground: UIColor
    @objc public let subCellBackground: UIColor
    @objc public let paperBackground: UIColor
    @objc public let popoverBackground: UIColor
    @objc public let chromeBackground: UIColor
    @objc public let chromeShadow: UIColor
    @objc public let overlayBackground: UIColor
    @objc public let batchSelectionBackground: UIColor
    @objc public let referenceHighlightBackground: UIColor
    @objc public let hintBackground: UIColor

    @objc public let overlayText: UIColor

    @objc public let primaryText: UIColor
    @objc public let secondaryText: UIColor
    @objc public let tertiaryText: UIColor
    @objc public let disabledText: UIColor
    @objc public let disabledLink: UIColor
    
    @objc public let chromeText: UIColor
    
    @objc public let link: UIColor
    @objc public let accent: UIColor
    @objc public let secondaryAction: UIColor
    @objc public let destructive: UIColor
    @objc public let warning: UIColor
    @objc public let error: UIColor
    @objc public let unselected: UIColor

    @objc public let border: UIColor
    @objc public let shadow: UIColor
    @objc public let cardBackground: UIColor
    @objc public let cardBorder: UIColor
    @objc public let cardShadow: UIColor
    @objc public let cardButtonBackground: UIColor

    @objc public let icon: UIColor?
    @objc public let iconBackground: UIColor?
    
    @objc public let searchFieldBackground: UIColor
    @objc public let keyboardBarSearchFieldBackground: UIColor
    
    @objc public let linkToAccent: Gradient
    
    @objc public let blurEffectStyle: UIBlurEffectStyle
    @objc public let blurEffectBackground: UIColor
    
    @objc public let tagText: UIColor
    @objc public let tagBackground: UIColor
    @objc public let tagSelectedBackground: UIColor

    //Someday, when the app is all swift, make this class a struct.
    init(baseBackground: UIColor, midBackground: UIColor, paperBackground: UIColor, chromeBackground: UIColor, popoverBackground: UIColor, subCellBackground: UIColor, overlayBackground: UIColor, batchSelectionBackground: UIColor, referenceHighlightBackground: UIColor, hintBackground: UIColor, overlayText: UIColor, searchFieldBackground: UIColor, keyboardBarSearchFieldBackground: UIColor, primaryText: UIColor, secondaryText: UIColor, tertiaryText: UIColor, disabledText: UIColor, disabledLink: UIColor, chromeText: UIColor, link: UIColor, accent: UIColor, border: UIColor, shadow: UIColor, chromeShadow: UIColor, cardBackground: UIColor, cardBorder: UIColor, cardShadow: UIColor, cardButtonBackground: UIColor, secondaryAction: UIColor, icon: UIColor?, iconBackground: UIColor?, destructive: UIColor, error: UIColor, warning: UIColor, unselected: UIColor, blurEffectStyle: UIBlurEffectStyle, blurEffectBackground: UIColor, tagText: UIColor, tagBackground: UIColor, tagSelectedBackground: UIColor) {
        self.baseBackground = baseBackground
        self.midBackground = midBackground
        self.subCellBackground = subCellBackground
        self.paperBackground = paperBackground
        self.popoverBackground = popoverBackground
        self.chromeBackground = chromeBackground
        self.chromeShadow = chromeShadow
        self.cardBackground = cardBackground
        self.cardBorder = cardBorder
        self.cardShadow = cardShadow
        self.cardButtonBackground = cardButtonBackground
        self.overlayBackground = overlayBackground
        self.batchSelectionBackground = batchSelectionBackground
        self.hintBackground = hintBackground
        self.referenceHighlightBackground = referenceHighlightBackground

        self.overlayText = overlayText
        
        self.searchFieldBackground = searchFieldBackground
        self.keyboardBarSearchFieldBackground = keyboardBarSearchFieldBackground
        
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.tertiaryText = tertiaryText
        self.disabledText = disabledText
        self.disabledLink = disabledLink

        self.chromeText = chromeText

        self.link = link
        self.accent = accent
        
        self.border = border
        self.shadow = shadow
        
        self.icon = icon
        self.iconBackground = iconBackground
        
        self.linkToAccent = Gradient(startColor: link, endColor: accent)
        
        self.error = error
        self.warning = warning
        self.destructive = destructive
        self.secondaryAction = secondaryAction
        self.unselected = unselected
        
        self.blurEffectStyle = blurEffectStyle
        self.blurEffectBackground = blurEffectBackground

        self.tagText = tagText
        self.tagBackground = tagBackground
        self.tagSelectedBackground = tagSelectedBackground
    }
}


@objc(WMFTheme)
public class Theme: NSObject {
    @objc public static let standard = Theme.light

    @objc public let colors: Colors
    
    @objc public let isDark: Bool
    
    @objc public var preferredStatusBarStyle: UIStatusBarStyle {
        return isDark ? .lightContent : .default
    }
    
    @objc public var scrollIndicatorStyle: UIScrollViewIndicatorStyle {
        return isDark ? .white : .black
    }
    
    @objc public var blurEffectStyle: UIBlurEffectStyle {
        return isDark ? .dark : .light
    }
    
    @objc public var keyboardAppearance: UIKeyboardAppearance {
        return isDark ? .dark : .light
    }

    @objc public lazy var navigationBarBackgroundImage: UIImage = {
        return UIImage.wmf_image(from: colors.paperBackground)
    }()
    
    @objc public lazy var navigationBarShadowImage: UIImage = {
        return #imageLiteral(resourceName: "transparent-pixel")
    }()
    
    static func roundedRectImage(with color: UIColor, cornerRadius: CGFloat, width: CGFloat? = nil, height: CGFloat? = nil) -> UIImage? {
        let minDimension = 2 * cornerRadius + 1
        let rect = CGRect(x: 0, y: 0, width: width ?? minDimension, height: height ?? minDimension)
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(color.cgColor)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        path.fill()
        let capInsets = UIEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius)
        let image = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: capInsets)
        UIGraphicsEndImageContext()
        return image
    }
    
    @objc public lazy var searchFieldBackgroundImage: UIImage? = {
        return Theme.roundedRectImage(with: colors.searchFieldBackground, cornerRadius: 10, height: 36)
    }()

    @objc public lazy var navigationBarTitleTextAttributes: [NSAttributedStringKey: Any] = {
        return [NSAttributedStringKey.foregroundColor: colors.chromeText]
    }()

    @objc public let imageOpacity: CGFloat
    
    @objc public let name: String
    @objc public let displayName: String

    @objc public let multiSelectIndicatorImage: UIImage?
    fileprivate static let lightMultiSelectIndicator = UIImage(named: "selected", in: Bundle.main, compatibleWith:nil)
    fileprivate static let darkMultiSelectIndicator = UIImage(named: "selected-dark", in: Bundle.main, compatibleWith:nil)
    
    @objc public static let light = Theme(colors: .light, imageOpacity: 1, multiSelectIndicatorImage: Theme.lightMultiSelectIndicator, isDark: false, name: "standard", displayName: WMFLocalizedString("theme-default-display-name", value: "Default", comment: "Default theme name presented to the user"))
    
    @objc public static let sepia = Theme(colors: .sepia, imageOpacity: 1, multiSelectIndicatorImage: Theme.lightMultiSelectIndicator, isDark: false, name: "sepia", displayName: WMFLocalizedString("theme-sepia-display-name", value: "Sepia", comment: "Sepia theme name presented to the user"))
    
    @objc public static let dark = Theme(colors: .dark, imageOpacity: 1, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, name: "dark", displayName: WMFLocalizedString("theme-dark-display-name", value: "Dark", comment: "Dark theme name presented to the user"))
    
    @objc public static let darkDimmed = Theme(colors: .dark, imageOpacity: 0.65, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, name: "dark-dimmed", displayName: Theme.dark.displayName)

    @objc public static let black = Theme(colors: .black, imageOpacity: 1, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, name: "black", displayName: WMFLocalizedString("theme-black-display-name", value: "Black", comment: "Black theme name presented to the user"))

    @objc public static let blackDimmed = Theme(colors: .black, imageOpacity: 0.65, multiSelectIndicatorImage: Theme.darkMultiSelectIndicator, isDark: true, name: "black-dimmed", displayName: Theme.black.displayName)

    @objc public static let widget = Theme(colors: .widget, imageOpacity: 1, multiSelectIndicatorImage: nil, isDark: false, name: "", displayName: "")
    
    init(colors: Colors, imageOpacity: CGFloat, multiSelectIndicatorImage: UIImage?, isDark: Bool, name: String, displayName: String) {
        self.colors = colors
        self.imageOpacity = imageOpacity
        self.name = name
        self.displayName = displayName
        self.multiSelectIndicatorImage = multiSelectIndicatorImage
        self.isDark = isDark
    }
    
    fileprivate static let themesByName = [Theme.light.name: Theme.light, Theme.dark.name: Theme.dark, Theme.sepia.name: Theme.sepia, Theme.darkDimmed.name: Theme.darkDimmed, Theme.black.name: Theme.black, Theme.blackDimmed.name: Theme.blackDimmed]
    
    @objc(withName:)
    public class func withName(_ name: String?) -> Theme? {
        guard let name = name else {
            return nil
        }
        return themesByName[name]
    }

    @objc public func withDimmingEnabled(_ isDimmingEnabled: Bool) -> Theme {
        guard let baseName = name.components(separatedBy: "-").first else {
            return self
        }
        let adjustedName = isDimmingEnabled ? "\(baseName)-dimmed" : baseName
        return Theme.withName(adjustedName) ?? self
    }
}

@objc(WMFThemeable)
public protocol Themeable : NSObjectProtocol {
    @objc(applyTheme:)
    func apply(theme: Theme) //this might be better as a var theme: Theme { get set } - common VC superclasses could check for viewIfLoaded and call an update method in the setter. This would elminate the need for the viewIfLoaded logic in every applyTheme:
}
