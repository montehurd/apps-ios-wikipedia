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




//Examples selections on 'en > Tamarack, MN > History'

  let textBeforeSelectedText = selection.anchorNode.textContent.slice(0, selection.anchorOffset)
// ^ will be empty string if selection starts at beggining of anchorNode - need to back up and grab text from prev node in this case 
//EXAMPLES: first 'was', second 'was'

// selection.getRangeAt(0).startContainer.previousSibling.textContent
// selection.getRangeAt(0).startContainer.parentNode.previousSibling.textContent
if (textBeforeSelectedText.length == 0) {
  const previousSibling = selection.anchorNode.previousSibling
  if (previousSibling) {
//EXAMPLE: '. The current'
    textBeforeSelectedText = previousSibling.textContent
  }
}
if (textBeforeSelectedText.length == 0) {
  const parentPreviousSibling = selection.anchorNode.parentNode.previousSibling
  if (parentPreviousSibling) {
//EXAMPLE: 'Aiken County' (note - no 't', this is italic too)
    textBeforeSelectedText = parentPreviousSibling.textContent
  }
}
// ^ broken for selecting last 'Counties' - because text before is only 'and Itasca'
// fix: need to grab more text before (for all 3 ways above)
//     try making more generic method for grabbing text around selection...



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






/*
new approach - 
think about how the example below uses 'addRange' to expand the selection...

*/

const expandSelectionTest = () => {

  var sel = window.getSelection()
  var range = sel.getRangeAt(0)

  var startEl = sel.anchorNode
  if (startEl != range.commonAncestorContainer) {
      while (startEl.parentNode != range.commonAncestorContainer) {
          startEl = startEl.parentNode
      }
  }
  var endEl = sel.focusNode
  if (endEl != range.commonAncestorContainer) {
      while (endEl.parentNode != range.commonAncestorContainer) {
          endEl = endEl.parentNode
      }
  }

  range.setStartBefore(startEl)
  range.setEndAfter(endEl)

  sel.addRange(range)

}
exports.expandSelectionTest = expandSelectionTest


/*
new approach for real.
- get selection text
- mark the selection by wrapping it with something identifable
  let span = document.createElement("<span>")
  span.id = 'myId'
  span.style.backgroundColor = 'red'
  selection.getRangeAt(0).surroundContents(span)
  (may not have to mark if we can record changing character positions)
  ACTUALLY can we save the initial range then do an intersection comparison after we modify the range???
- call the method below to expand the selection
- get the text before 'myId' and after it
- now we have the selection text and enough text before and after for disambiguation!!!

*/
const expandSelectionTest2 = () => {
  var sel = window.getSelection()
  var range = sel.getRangeAt(0)

const selectedText = range.toString()

// let span = document.createElement('span')
// span.id = 'myId'
// range.surroundContents(span)


  var startEl = sel.anchorNode
  if (startEl != range.commonAncestorContainer) {
      while (startEl.parentNode != range.commonAncestorContainer) {
          startEl = startEl.parentNode
      }
  }
  var endEl = sel.focusNode
  if (endEl != range.commonAncestorContainer) {
      while (endEl.parentNode != range.commonAncestorContainer) {
          endEl = endEl.parentNode
      }
  }

  // range.setStartBefore(startEl)
  // range.setEndAfter(endEl)

  // range.setStartBefore(startEl.previousSibling) // < expands back by one sibling
  // range.setEndAfter(endEl.nextSibling) // < expands forward by one sibling

  range.setStartBefore(startEl.previousSibling || startEl.parentNode.previousSibling || sel.anchorNode) //
const text2 = range.toString()
const beforeSelectedText = text2.slice(0, -selectedText.length)

  range.setEndAfter(endEl.nextSibling || endEl.parentNode.nextSibling || sel.focusNode) //
const text3 = range.toString()
const afterSelectedText = text3.slice(text2.length)

  sel.addRange(range)

  return {
    selectedText,
    beforeSelectedText,
    afterSelectedText
  }
}
exports.expandSelectionTest2 = expandSelectionTest2
















exports.getSelectedTextEditInfo = getSelectedTextEditInfo