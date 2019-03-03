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
  
  const selectedAndAdjacentTest = getSelectedAndAdjacentTest(selection)

  return new SelectedTextInfo(
    selectedAndAdjacentTest['selectedText'], 
    isTitleDescriptionSelection, 
    sectionID, 
    selectedAndAdjacentTest['textBeforeSelectedText'], 
    selectedAndAdjacentTest['textAfterSelectedText']
  )
}

// Ensure adjacent text extraction works for these tricky examples on 'en > Tamarack, MN > History':
// Things to select and try:
// - the first 'was', the second 'was'
// - '. The current'
// - 'Aiken County' (note - no 't', this is italic too)
const getSelectedAndAdjacentTest = (sel) => {
  const range = sel.getRangeAt(0)
  const selectedText = range.toString()

  let startEl = sel.anchorNode
  if (startEl != range.commonAncestorContainer) {
      while (startEl.parentNode != range.commonAncestorContainer) {
          startEl = startEl.parentNode
      }
  }
  let endEl = sel.focusNode
  if (endEl != range.commonAncestorContainer) {
      while (endEl.parentNode != range.commonAncestorContainer) {
          endEl = endEl.parentNode
      }
  }



// The word 'created' in: "The county was created in 1857 and organized in 1871."

  range.setStartBefore(startEl.previousSibling || startEl.parentNode.previousSibling || sel.anchorNode)
  const beforeAndSelectedText = range.toString()
  let textBeforeSelectedText = beforeAndSelectedText.slice(0, -selectedText.length)

// in textBeforeSelectedText remove anything before last line break
const aa = textBeforeSelectedText.split('\n')
textBeforeSelectedText = aa[aa.length - 1]



  range.setEndAfter(endEl.nextSibling || endEl.parentNode.nextSibling || sel.focusNode)
  const beforeAndAfterAndSelectedText = range.toString()
  let textAfterSelectedText = beforeAndAfterAndSelectedText.slice(beforeAndSelectedText.length)

// in textAfterSelectedText remove anything after first line break
const bb = textAfterSelectedText.split('\n')
textAfterSelectedText = bb[0]





  // Uncomment for debugging - actually changes the selection visibly.
  // sel.addRange(range)

  return {
    selectedText,
    textBeforeSelectedText,
    textAfterSelectedText
  }
}

exports.getSelectedTextEditInfo = getSelectedTextEditInfo