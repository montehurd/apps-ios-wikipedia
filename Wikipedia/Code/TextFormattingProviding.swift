protocol TextFormattingProviding: class {
    var delegate: TextFormattingDelegate? { get set }
}

protocol TextFormattingButtonsProviding: TextFormattingProviding {
    var buttons: [TextFormattingButton] { get set }
}

extension TextFormattingButtonsProviding {
    func selectButton(_ button: SectionEditorWebViewMessagingController.Button) {
        buttons.lazy.first(where: { $0.tag == button.kind.identifier })?.isSelected = true
    }

    func disableButton(_ button: SectionEditorWebViewMessagingController.Button) {
        buttons.lazy.first(where: { $0.tag == button.kind.identifier })?.isEnabled = false
    }

    func enableAllButtons() {
        buttons.lazy.forEach { $0.isEnabled = true }
    }

    func deselectAllButtons() {
        buttons.lazy.forEach { $0.isSelected = false }
    }
}
protocol TextFormattingDelegate: class {
    func textFormattingProvidingDidTapClose()
    func textFormattingProvidingDidTapHeading(depth: Int)
    func textFormattingProvidingDidTapBold()
    func textFormattingProvidingDidTapItalics()
    func textFormattingProvidingDidTapUnderline()
    func textFormattingProvidingDidTapStrikethrough()
    func textFormattingProvidingDidTapReference()
    func textFormattingProvidingDidTapTemplate()
    func textFormattingProvidingDidTapComment()
    func textFormattingProvidingDidTapLink()
    func textFormattingProvidingDidTapIncreaseIndent()
    func textFormattingProvidingDidTapDecreaseIndent()
    func textFormattingProvidingDidTapOrderedList()
    func textFormattingProvidingDidTapUnorderedList()
    func textFormattingProvidingDidTapSuperscript()
    func textFormattingProvidingDidTapSubscript()
    func textFormattingProvidingDidTapCursorUp()
    func textFormattingProvidingDidTapCursorDown()
    func textFormattingProvidingDidTapCursorRight()
    func textFormattingProvidingDidTapCursorLeft()
    func textFormattingProvidingDidTapMore()
    func textFormattingProvidingDidTapTextSize(newSize: TextSizeType)

    func textFormattingProvidingDidTapTextFormatting()
    func textFormattingProvidingDidTapTextStyleFormatting()
}
