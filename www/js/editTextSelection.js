const utilities = require('./utilities')

class SelectedTextInfo {
  constructor(selectedText, isSelectedTextInTitleDescription, sectionID, textBeforeSelectedText, textAfterSelectedText) {
    this.selectedText = selectedText
    this.isSelectedTextInTitleDescription = isSelectedTextInTitleDescription
    this.sectionID = sectionID
    this.textBeforeSelectedText = textBeforeSelectedText
    this.textAfterSelectedText = textAfterSelectedText
  }
}

const isSelectedTextInTitleDescription = selection => utilities.findClosest(selection.anchorNode, 'p#pagelib_edit_section_title_description') != null

const getSelectedTextSectionID = selection => {
  const sectionIDString = utilities.findClosest(selection.anchorNode, 'div[id^="section_heading_and_content_block_"]').id.slice('section_heading_and_content_block_'.length)
  if (sectionIDString == null) {
    return null
  }
  return parseInt(sectionIDString)
}

const getSelectedTextEditInfo = () => {
  const selection = window.getSelection()
  const isTitleDescriptionSelection = isSelectedTextInTitleDescription(selection)
  let sectionID = 0
  if (!isTitleDescriptionSelection) {
    sectionID = getSelectedTextSectionID(selection)
  }

  const selectedText = selection.toString()
  const fullAnchorNodeText = selection.anchorNode.textContent
  const textBeforeSelectedText = selection.anchorNode.textContent.slice(0, selection.anchorOffset)
  const textAfterSelectedText = selection.extentNode.textContent.slice(selection.extentOffset)

  return new SelectedTextInfo(selectedText, isTitleDescriptionSelection, sectionID, textBeforeSelectedText, textAfterSelectedText)
}

exports.getSelectedTextEditInfo = getSelectedTextEditInfo