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






  let textBeforeSelectedText = selection.anchorNode.textContent.slice(0, selection.anchorOffset)
// ^ will be empty string if selection starts at beggining of anchorNode - need to back up and grab text from prev node in this case 

// selection.getRangeAt(0).startContainer.previousSibling.textContent
// selection.getRangeAt(0).startContainer.parentNode.previousSibling.textContent
if (textBeforeSelectedText.length == 0) {
  const previousSibling = selection.anchorNode.previousSibling
  if (previousSibling) {
    textBeforeSelectedText = previousSibling.textContent
  }
}
if (textBeforeSelectedText.length == 0) {
  const parentPreviousSibling = selection.anchorNode.parentNode.previousSibling
  if (parentPreviousSibling) {
    textBeforeSelectedText = parentPreviousSibling.textContent
  }
}




  let textAfterSelectedText = selection.extentNode.textContent.slice(selection.extentOffset)
// ^ will be empty string if selection ends at end of anchorNode - need to go forward and grab text from next node in this case 

// selection.getRangeAt(0).endContainer.nextSibling.textContent
// selection.getRangeAt(0).endContainer.parentNode.nextSibling.textContent
if (textAfterSelectedText.length == 0) {
  const nextSibling = selection.extentNode.nextSibling
  if (nextSibling) {
    textAfterSelectedText = nextSibling.textContent
  }
}
if (textAfterSelectedText.length == 0) {
  const parentNextSibling = selection.extentNode.parentNode.nextSibling
  if (parentNextSibling) {
    textAfterSelectedText = parentNextSibling.textContent
  }
}






  return new SelectedTextInfo(selectedText, isTitleDescriptionSelection, sectionID, textBeforeSelectedText, textAfterSelectedText)
}

exports.getSelectedTextEditInfo = getSelectedTextEditInfo