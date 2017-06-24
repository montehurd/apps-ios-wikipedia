import UIKit

@objc(WMFOnThisDayCollectionViewCell)
class OnThisDayCollectionViewCell: SideScrollingCollectionViewCell {

    let timelineView = OnThisDayTimelineView()

    @objc(configureWithOnThisDayEvent:dataStore:layoutOnly:)
    func configure(with onThisDayEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, layoutOnly: Bool) {
        let previews = onThisDayEvent.articlePreviews ?? []
        let currentYear = Calendar.current.component(.year, from: Date())
        
        titleLabel.textColor = .wmf_blue
        subTitleLabel.textColor = .wmf_customGray
        
        titleLabel.text = onThisDayEvent.yearWithEraString()

        if let eventYear = onThisDayEvent.year {
            let yearsSinceEvent = currentYear - eventYear.intValue
            subTitleLabel.text = String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.yearsAgo(), yearsSinceEvent)
        } else {
            subTitleLabel.text = nil
        }
            
        descriptionLabel.text = onThisDayEvent.text
        
        articles = previews.map { (articlePreview) -> CellArticle in
            let articleLanguage = (articlePreview.articleURL as NSURL?)?.wmf_language
            let description = articlePreview.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: articleLanguage)
            return CellArticle(articleURL:articlePreview.articleURL, title: articlePreview.displayTitle, description: description, imageURL: articlePreview.thumbnailURL)
        }
        
        let articleLanguage = (onThisDayEvent.articlePreviews?.first?.articleURL as NSURL?)?.wmf_language
        descriptionLabel.accessibilityLanguage = articleLanguage
        semanticContentAttributeOverride = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        
        isImageViewHidden = true

        setNeedsLayout()
    }
    
    static let descriptionTextStyle = UIFontTextStyle.subheadline
    var descriptionFont = UIFont.preferredFont(forTextStyle: descriptionTextStyle)
    
    static let titleTextStyle = UIFontTextStyle.title3
    var titleFont = UIFont.preferredFont(forTextStyle: titleTextStyle)
    
    static let subTitleTextStyle = UIFontTextStyle.subheadline
    var subTitleFont = UIFont.preferredFont(forTextStyle: subTitleTextStyle)
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = titleFont
        subTitleLabel.font = subTitleFont
        descriptionLabel.font = descriptionFont
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {

        let timelineViewWidth:CGFloat = 66.0
        timelineView.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: timelineViewWidth, height: bounds.size.height)
        
        margins.left = timelineViewWidth
        return super.sizeThatFits(size, apply: apply)
    }
    
    override open func setup() {
        super.setup()
        collectionView.backgroundColor = .clear
        insertSubview(timelineView, belowSubview: collectionView)
    }
    
    
    
    
    

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    var shouldAnimateDots: Bool = false
    
    func startDotAnimation() {
        displayLink?.isPaused = false
    }

    func endDotAnimation() {
        displayLink?.isPaused = true
    }

    lazy var displayLink: CADisplayLink? = {
        guard self.shouldAnimateDots == true else {
            return nil
        }
        let link = CADisplayLink(target: self.timelineView, selector: #selector(OnThisDayTimelineView.handleDisplayLink(_:)))
        link.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        return link
    }()

    override func removeFromSuperview() {
        displayLink?.invalidate()
        displayLink = nil
        super.removeFromSuperview()
    }
    
    override var isHidden: Bool {
        didSet {
            displayLink?.isPaused = isHidden
        }
    }

    
    
    
    
    
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        timelineView.dotY = titleLabel.convert(titleLabel.bounds, to: timelineView).midY
    }
    
    
    
    
    
    
}











class OnThisDayTimelineView: UIView {

    
    lazy var outerDotShapeLayer: CAShapeLayer = {
        let outerDotShapeLayer = CAShapeLayer()
        
        outerDotShapeLayer.fillColor = UIColor.white.cgColor
        outerDotShapeLayer.strokeColor = UIColor.wmf_blue.cgColor
        outerDotShapeLayer.lineWidth = 1.0
        
        self.layer.addSublayer(outerDotShapeLayer)
        return outerDotShapeLayer
    }()

    lazy var innerDotShapeLayer: CAShapeLayer = {
        let innerDotShapeLayer = CAShapeLayer()
        
        innerDotShapeLayer.fillColor = UIColor.wmf_blue.cgColor
        innerDotShapeLayer.strokeColor = UIColor.wmf_blue.cgColor
        innerDotShapeLayer.lineWidth = 1.0
        
        self.layer.addSublayer(innerDotShapeLayer)
        return innerDotShapeLayer
    }()
    
    
    
    

    
    
    
    var dotY: CGFloat = 0
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open func setup() {
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.wmf_blue.cgColor)
        context.move(to: CGPoint(x: rect.midX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        context.strokePath()
    }
    
    // Returns CGFloat in range from 0.0 to 1.0. 0.0 indicates dot should be minimized.
    // 1.0 indicates dot should be maximized. Approaches 1.0 as timelineView.dotY
    // approaches vertical center. Approaches 0.0 as timelineView.dotY approaches top
    // or bottom.
    func dotAnimationNormal(with y:CGFloat) -> CGFloat {
        guard let window = window else {
            return 0.0
        }
        
        let yInWindow = convert(CGPoint(x:0, y:y), to: window).y
        let halfWindowHeight = window.bounds.size.height * 0.5
        let normY = max(0.0, 1.0 - (abs(yInWindow - halfWindowHeight) / halfWindowHeight))
        let roundedNormY = (normY * 10).rounded(.up) / 10
        return roundedNormY
    }

    var lastDotAnimationNorm: CGFloat = -1.0 // -1.0 so dots with dotAnimationNormal of "0.0" are visible initially
    
    public func handleDisplayLink(_ displayLink: CADisplayLink) {
        
        let yOffset:CGFloat = 120.0 // shift the "maximum dot" point up a bit (otherwise it's in the vertical center of screen)
        let thisDotAnimationNormal = dotAnimationNormal(with: dotY + yOffset)
        
        if thisDotAnimationNormal == lastDotAnimationNorm {
            return
        }
        
        let dotCenter = CGPoint(x: frame.midX, y: dotY)
        
        outerDotShapeLayer.path = UIBezierPath(arcCenter: dotCenter, radius: CGFloat(8.0 * max(thisDotAnimationNormal, 0.4)), startAngle: 0.0, endAngle:CGFloat.pi * 2.0, clockwise: true).cgPath
        
        innerDotShapeLayer.path = UIBezierPath(arcCenter: dotCenter, radius: CGFloat(8.0 * max((thisDotAnimationNormal - 0.4), 0.0)), startAngle: 0.0, endAngle:CGFloat.pi * 2.0, clockwise: true).cgPath
        
        lastDotAnimationNorm = thisDotAnimationNormal
    }
}





























































