const ItemRange = require('./codemirror-range-objects').ItemRange
const ItemLocation = require('./codemirror-range-objects').ItemLocation
const SetUtilites = require('./codemirror-range-set-utilities')
const markupItemsForLineTokens = require('./codemirror-range-determination').markupItemsForLineTokens

const getItemRangeFromSelection = (codeMirror) => {
  const fromCursor = codeMirror.getCursor('from')
  const toCursor = codeMirror.getCursor('to')
  const fromLocation = new ItemLocation(fromCursor.line, fromCursor.ch)
  const toLocation = new ItemLocation(toCursor.line, toCursor.ch)
  const selectionRange = new ItemRange(fromLocation, toLocation)
  return selectionRange
}

const getButtonNamesIntersectingSelection = (codeMirror) => {
  const selectionRange = getItemRangeFromSelection(codeMirror)

  const line = codeMirror.getCursor().line
  const lineTokens = codeMirror.getLineTokens(line, true)
  const markupItems = markupItemsForLineTokens(lineTokens, line)
  
  const buttonNames = markupItems.filter(item => item.outerRange.intersectsRange(selectionRange)).map(item => item.buttonName)
  
  return buttonNames
}

exports.getItemRangeFromSelection = getItemRangeFromSelection
exports.getButtonNamesIntersectingSelection = getButtonNamesIntersectingSelection