import UIKit

protocol DefaultEditToolbarViewDelegate: class {
    func defaultEditToolbarViewDidTapTextFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapHeaderFormattingButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapCitationButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapLinkButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapUnorderedListButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapOrderedListButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    // Indentation
    func defaultEditToolbarViewDidTapDecreaseIndentationUpButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapIncreaseIndentationUpButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    // Cursor movement
    func defaultEditToolbarViewDidTapCursorUpButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapCursorDownButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapCursorLeftButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    func defaultEditToolbarViewDidTapCursorRightButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
    // Find in page
    // TODO
    // More
    func defaultEditToolbarViewDidTapMoreButton(_ defaultEditToolbarView: DefaultEditToolbarView, button: UIButton)
}

class DefaultEditToolbarView: EditToolbarView {
    weak var delegate: DefaultEditToolbarViewDelegate?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var chevronButton: UIButton!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!

    override func awakeFromNib() {
        super.awakeFromNib()
        chevronButton.imageView?.contentMode = .scaleAspectFit
layer.borderColor = UIColor.red.cgColor
layer.borderWidth = 10
    }

    private func button(withTitle title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func button(withImage image: UIImage, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: Button actions

    @IBAction private func formatText(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapTextFormattingButton(self, button: sender)
    }

    @IBAction private func formatHeader(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapHeaderFormattingButton(self, button: sender)
    }

    @IBAction private func toggleCitation(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapCitationButton(self, button: sender)
    }

    @IBAction private func toggleLink(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapLinkButton(self, button: sender)
    }

    @IBAction private func toggleUnorderedList(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapUnorderedListButton(self, button: sender)
    }

    @IBAction private func toggleOrderedList(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapOrderedListButton(self, button: sender)
    }

    @IBAction private func decreaseIndentation(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapDecreaseIndentationUpButton(self, button: sender)
    }

    @IBAction private func increaseIndentation(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapIncreaseIndentationUpButton(self, button: sender)
    }

    @IBAction private func moveCursorUp(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapCursorUpButton(self, button: sender)
    }

    @IBAction private func moveCursorDown(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapCursorDownButton(self, button: sender)
    }

    @IBAction private func moveCursorLeft(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapCursorLeftButton(self, button: sender)
    }

    @IBAction private func moveCursorRight(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapCursorRightButton(self, button: sender)
    }

    @IBAction private func showMore(_ sender: UIButton) {
        delegate?.defaultEditToolbarViewDidTapMoreButton(self, button: sender)
    }

    private enum ActionsType: CGFloat {
        case `default`
        case secondary

        static func visible(rawValue: RawValue) -> ActionsType {
            if rawValue == 0 {
                return .default
            } else {
                return .secondary
            }
        }

        static func next(rawValue: RawValue) -> ActionsType {
            if rawValue == 0 {
                return .secondary
            } else {
                return .default
            }
        }
    }

    @IBAction private func revealMoreActionsViaTap(_ gestureRecognizer: UITapGestureRecognizer) {
        revealMoreActions(chevronButton)
    }

    @IBAction private func revealMoreActions(_ sender: UIButton) {
        let offsetX = scrollView.contentOffset.x
        let actionsType = ActionsType.next(rawValue: offsetX)
        revealMoreActions(ofType: actionsType, with: sender, animated: true)
    }

    private func revealMoreActions(ofType actionsType: ActionsType, with sender: UIButton, animated: Bool) {
        let transform = CGAffineTransform.identity
        let buttonTransform: () -> Void
        let newOffsetX: CGFloat

        switch actionsType {
        case .default:
            buttonTransform = {
                sender.transform = transform
            }
            newOffsetX = 0
        case .secondary:
            buttonTransform = {
                sender.transform = transform.rotated(by: 180 * CGFloat.pi)
                sender.transform = transform.rotated(by: -1 * CGFloat.pi)
            }
            newOffsetX = stackView.bounds.width / 2
        }

        let scrollViewContentOffsetChange = {
            self.scrollView.setContentOffset(CGPoint(x: newOffsetX , y: 0), animated: false)
        }

        if animated {
            let buttonAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.7, animations: buttonTransform)
            let scrollViewAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut, animations: scrollViewContentOffsetChange)

            buttonAnimator.startAnimation()
            scrollViewAnimator.startAnimation()
        } else {
            buttonTransform()
            scrollViewContentOffsetChange()
        }
    }
}

extension DefaultEditToolbarView {
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        //
    }
}
