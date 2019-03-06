const utilities = require('./utilities')

class SelectedTextEditInfo {
  constructor(selectedAndAdjacentText, isSelectedTextInTitleDescription, sectionID) {
    this.selectedAndAdjacentText = selectedAndAdjacentText
    this.isSelectedTextInTitleDescription = isSelectedTextInTitleDescription
    this.sectionID = sectionID
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
  
  const selectedAndAdjacentText = getSelectedAndAdjacentText(selection)

  return new SelectedTextEditInfo(
    selectedAndAdjacentText,
    isTitleDescriptionSelection, 
    sectionID
  )
}

class SelectedAndAdjacentText {
  constructor(selectedText, textBeforeSelectedText, textAfterSelectedText) {
    this.selectedText = selectedText
    this.textBeforeSelectedText = textBeforeSelectedText
    this.textAfterSelectedText = textAfterSelectedText
  }
}

const getSelectedAndAdjacentText = (selection) => {
  const range = selection.getRangeAt(0)
  const selectedText = range.toString()

  let startNode = selection.anchorNode
  if (startNode != range.commonAncestorContainer) {
      while (startNode.parentNode != range.commonAncestorContainer) {
          startNode = startNode.parentNode
      }
  }
  let endNode = selection.focusNode
  if (endNode != range.commonAncestorContainer) {
      while (endNode.parentNode != range.commonAncestorContainer) {
          endNode = endNode.parentNode
      }
  }

  range.setStartBefore(startNode.previousSibling || startNode.parentNode.previousSibling || selection.anchorNode)
  const beforeAndSelectedText = range.toString()
  const textBeforeSelectedText = trimEverythingBeforeLastLineBreak(beforeAndSelectedText.slice(0, -selectedText.length))

  range.setEndAfter(endNode.nextSibling || endNode.parentNode.nextSibling || selection.focusNode)
  const beforeAndAfterAndSelectedText = range.toString()
  const textAfterSelectedText = trimEverythingAfterFirstLineBreak(beforeAndAfterAndSelectedText.slice(beforeAndSelectedText.length))

  // Uncomment for debugging - actually changes the selection visibly.
  // selection.addRange(range)

  return new SelectedAndAdjacentText(selectedText, textBeforeSelectedText, textAfterSelectedText)
}

const trimEverythingAfterFirstLineBreak = (s) => s.split('\n')[0]  

const trimEverythingBeforeLastLineBreak = (s) => {
  const lines = s.split('\n')
  return lines[lines.length - 1]
}

exports.getSelectedTextEditInfo = getSelectedTextEditInfo