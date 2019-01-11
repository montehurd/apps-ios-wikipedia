protocol SectionEditorNavigationItemControllerDelegate: class {
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapProgressButton progressButton: UIBarButtonItem)
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapCloseButton closeButton: UIBarButtonItem)
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapUndoButton undoButton: UIBarButtonItem)
    func sectionEditorNavigationItemController(_ sectionEditorNavigationItemController: SectionEditorNavigationItemController, didTapRedoButton redoButton: UIBarButtonItem)
}

class SectionEditorNavigationItemController: NSObject, Themeable {
    weak var navigationItem: UINavigationItem?

    init(navigationItem: UINavigationItem) {
        self.navigationItem = navigationItem
        super.init()
        configureNavigationButtonItems()
    }

    func apply(theme: Theme) {
        for case let barButonItem as BarButtonItem in navigationItem?.rightBarButtonItems ?? [] {
            barButonItem.apply(theme: theme)
        }
        for case let barButonItem as BarButtonItem in navigationItem?.leftBarButtonItems ?? [] {
            barButonItem.apply(theme: theme)
        }
    }

    weak var delegate: SectionEditorNavigationItemControllerDelegate?

    private class BarButtonItem: UIBarButtonItem, Themeable {
        var tintColorKeyPath: KeyPath<Theme, UIColor>?

        convenience init(title: String?, style: UIBarButtonItem.Style, target: Any?, action: Selector?, tintColorKeyPath: KeyPath<Theme, UIColor>) {
            self.init(title: title, style: style, target: target, action: action)
            self.tintColorKeyPath = tintColorKeyPath
        }

        convenience init(image: UIImage?, style: UIBarButtonItem.Style, target: Any?, action: Selector?, tintColorKeyPath: KeyPath<Theme, UIColor>) {
            let button = UIButton(type: .system)
            button.setImage(image, for: .normal)
            if let target = target, let action = action {
                button.addTarget(target, action: action, for: .touchUpInside)
            }
            self.init(customView: button)
            self.tintColorKeyPath = tintColorKeyPath
        }

        func apply(theme: Theme) {
            guard let tintColorKeyPath = tintColorKeyPath else {
                return
            }
            let newTintColor = theme[keyPath: tintColorKeyPath]
            if customView == nil {
                tintColor = newTintColor
            } else if let button = customView as? UIButton {
                button.tintColor = newTintColor
            }
        }
    }

    private lazy var progressButton: BarButtonItem = {
        return BarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(progress(_:)), tintColorKeyPath: \Theme.colors.link)
    }()

    private lazy var redoButton: BarButtonItem = {
        return BarButtonItem(image: #imageLiteral(resourceName: "redo"), style: .plain, target: self, action: #selector(redo(_ :)), tintColorKeyPath: \Theme.colors.primaryText)
    }()

    private lazy var undoButton: BarButtonItem = {
        return BarButtonItem(image: #imageLiteral(resourceName: "undo"), style: .plain, target: self, action: #selector(undo(_ :)), tintColorKeyPath: \Theme.colors.primaryText)
    }()

    private lazy var separatorButton: BarButtonItem = {
        let button = BarButtonItem(image: #imageLiteral(resourceName: "separator"), style: .plain, target: nil, action: nil, tintColorKeyPath: \Theme.colors.chromeText)
        button.isEnabled = false
        return button
    }()

    @objc private func progress(_ sender: UIBarButtonItem) {
        delegate?.sectionEditorNavigationItemController(self, didTapProgressButton: sender)
    }

    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.sectionEditorNavigationItemController(self, didTapCloseButton: sender)
    }

    @objc private func undo(_ sender: UIBarButtonItem) {
        delegate?.sectionEditorNavigationItemController(self, didTapUndoButton: undoButton)
    }

    @objc private func redo(_ sender: UIBarButtonItem) {
        delegate?.sectionEditorNavigationItemController(self, didTapRedoButton: sender)
    }

    private func configureNavigationButtonItems() {
        let closeButton = BarButtonItem(image: #imageLiteral(resourceName: "close"), style: .plain, target: self, action: #selector(close(_ :)), tintColorKeyPath: \Theme.colors.chromeText)
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        navigationItem?.leftBarButtonItem = closeButton

        navigationItem?.rightBarButtonItems = [
            progressButton,
            UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 20),
            separatorButton,
            UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 20),
            redoButton,
            UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 20),
            undoButton
        ]

//        progressButton.isEnabled = false
    }

    func textSelectionDidChange(isRangeSelected: Bool) {

undoButton.isEnabled = true
redoButton.isEnabled = true
progressButton.isEnabled = true
//        undoButton.isEnabled = false
//        redoButton.isEnabled = false
    }

    func disableButton(button: SectionEditorWebViewMessagingController.Button) {
        switch button.kind {
        case .undo:
            undoButton.isEnabled = false
        case .redo:
            redoButton.isEnabled = false
        case .progress:
            progressButton.isEnabled = false
        default:
            break
        }
    }
    
    func buttonSelectionDidChange(button: SectionEditorWebViewMessagingController.Button) {
        switch button.kind {
//        case .undo:
//            undoButton.isEnabled = true
//        case .redo:
//            redoButton.isEnabled = true
//        case .progress(let changesMade):
//            progressButton.isEnabled = changesMade
        default:
            break
        }
    }
}
