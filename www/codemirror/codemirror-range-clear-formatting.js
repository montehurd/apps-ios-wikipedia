const ItemRange = require('./codemirror-range-objects').ItemRange
const ItemLocation = require('./codemirror-range-objects').ItemLocation

const getItemRangeFromSelection = require('./codemirror-range-utilities').getItemRangeFromSelection
const getMarkupItemsIntersectingSelection = require('./codemirror-range-utilities').getMarkupItemsIntersectingSelection
const getButtonNamesFromMarkupItems = require('./codemirror-range-utilities').getButtonNamesFromMarkupItems
const markupItemsForItemRangeLines = require('./codemirror-range-determination').markupItemsForItemRangeLines

const markupItemsStartingOrEndingInSelectionRange = (codeMirror, selectionRange) =>
  markupItemsForItemRangeLines(codeMirror, selectionRange).filter(item => item.innerRangeStartsOrEndsInRange(selectionRange, true))


// const markupItemsNotStartingOrEndingInSelectionRange = (codeMirror, selectionRange) =>
//   markupItemsForItemRangeLines(codeMirror, selectionRange).filter(item => !item.innerRangeStartsOrEndsInRange(selectionRange, false))


// const markupItems123 = (codeMirror, selectionRange) =>
//   markupItemsForItemRangeLines(codeMirror, selectionRange)
//   .filter(item => item.innerRange.intersectsRange(selectionRange, true))
//   .filter(item => !item.innerRangeStartsOrEndsInRange(selectionRange, false))
//   .filter(item => !selectionRange.startsInsideRange(item.openingMarkupRange(), false))
//   .filter(item => !selectionRange.startsInsideRange(item.closingMarkupRange(), false))
//   .filter(item => !selectionRange.endsInsideRange(item.openingMarkupRange(), false))
//   .filter(item => !selectionRange.endsInsideRange(item.closingMarkupRange(), false))

const canClearFormatting = (codeMirror) => {
  
//FORCE for testing addMarkupAroundSelectionRange
return true  
  
  let selectionRange = getItemRangeFromSelection(codeMirror)
  if (selectionRange.isZeroLength()) {
    return false
  }

  const markupItems = markupItemsStartingOrEndingInSelectionRange(codeMirror, selectionRange)
  const markupItemsIntersectingSelection = getMarkupItemsIntersectingSelection(codeMirror, markupItems, selectionRange)
  const buttonNames = getButtonNamesFromMarkupItems(markupItemsIntersectingSelection)
  if (buttonNames.includes('reference') || buttonNames.includes('template')) {
    return false
  }
  
  return canRelocateOrRemoveExistingMarkupForSelectionRange(codeMirror)

// will need to account for canAddMarkupAroundSelectionRange here too!

}

const clearFormatting = (codeMirror) => {
//  relocateOrRemoveExistingMarkupForSelectionRange(codeMirror, false)

addMarkupAroundSelectionRange(codeMirror, false)

}










//TODO: can we split out the 2 removal/relocate and addition logic to separate files?



const canAddMarkupAroundSelectionRange = (codeMirror) => addMarkupAroundSelectionRange(codeMirror, true)

const addMarkupAroundSelectionRange = (codeMirror, evaluateOnly = false) => {
  const selectionRange = getItemRangeFromSelection(codeMirror)



  /*
    - use markupItemsInSelectionRange 
  */

  //bail if any markup items start or end in selection
  // if (markupItemsStartingOrEndingInSelectionRange(codeMirror, selectionRange).length > 0) {
  //   return
  // }

  // const markupItems = markupItemsNotStartingOrEndingInSelectionRange(codeMirror, selectionRange)
  //   .filter((item => item.innerRange.intersectsRange(selectionRange, true)))







let markupItems = markupItemsForItemRangeLines(codeMirror, selectionRange)

const markupItemOpeningOrClosingMarkupIntersectsSelectionRange = (item) => item.openingMarkupRange().intersectsRange(selectionRange, false) || item.closingMarkupRange().intersectsRange(selectionRange, false)

const selectionIncludesAnyOpeningOrClosingMarkup = markupItems.find(markupItemOpeningOrClosingMarkupIntersectsSelectionRange) !== undefined

if (selectionIncludesAnyOpeningOrClosingMarkup) {
  return
}

const selectionIntersectsItemInnerRange = (item) => item.innerRange.intersectsRange(selectionRange, true)
markupItems = markupItems.filter(selectionIntersectsItemInnerRange)// === undefined
// return if selection doesn't intersect with any markup items (selected word at end of line after last markup item etc)
if (markupItems.length === 0) {
  return
}



// AFTER the code below need to collapse EMPTY item ranges - ie <sup></sup> or ''''''
// OR if CM doesn't tokenize these correctly insert an extra space if we detect and EMPTY range will be the result of change











  // at selection end add opening tags for all markup items
  // at selection start add closing tags for all markup items

  let markupRangesToAddBeforeSelection = []
  let markupRangesToAddAfterSelection = []

  markupItems.forEach(item => {
    markupRangesToAddBeforeSelection.unshift(item.closingMarkupRange())
    markupRangesToAddAfterSelection.push(item.openingMarkupRange())
  })

  let accumulatedLeftMarkup = getTextFromRanges(codeMirror, markupRangesToAddBeforeSelection)
  let accumulatedRightMarkup = getTextFromRanges(codeMirror, markupRangesToAddAfterSelection)



const removalMarker = 'REMOVE_ME'
// Work-around for Codemirror incorrectly tokenizing empty markup items (i.e. <sup></sup> or '''')
// Simply adds `COLLAPSE_ME` where addition would result in empty item. makes it easy to strip these.
// Otherwise they'd be incorrectly tokenized and things would get explodey.
const selectionStartsAtOpeningMarkupEnd = markupItems.find(item => item.openingMarkupRange().endLocation.equals(selectionRange.startLocation)) !== undefined
if (selectionStartsAtOpeningMarkupEnd) {
  accumulatedLeftMarkup = `${removalMarker}${accumulatedLeftMarkup}`
}
const selectionEndsAtClosingMarkupStart = markupItems.find(item => item.closingMarkupRange().startLocation.equals(selectionRange.endLocation)) !== undefined
if (selectionEndsAtClosingMarkupStart) {
  accumulatedRightMarkup = `${accumulatedRightMarkup}${removalMarker}`
}



  codeMirror.replaceRange(accumulatedRightMarkup, selectionRange.endLocation, null, '+')
  codeMirror.replaceRange(accumulatedLeftMarkup, selectionRange.startLocation, null, '+')



// Strip out 'removalMarker' items.
const markupItems2 = markupItemsForItemRangeLines(codeMirror, selectionRange)
markupItems2.forEach(item => {
  if (codeMirror.getRange(item.innerRange.startLocation, item.innerRange.endLocation) === removalMarker) {
    codeMirror.replaceRange('', item.outerRange.startLocation, item.outerRange.endLocation, '+')
  }
})






const origSelectionRangeLineExtent = selectionRange.endLocation.line - selectionRange.startLocation.line
const origSelectionRangeChExtent = selectionRange.endLocation.ch - selectionRange.startLocation.ch
const newSelectionRange = getItemRangeFromSelection(codeMirror)

  codeMirror.setSelection(
    newSelectionRange.startLocation, 
    newSelectionRange.startLocation.withOffset(origSelectionRangeLineExtent, origSelectionRangeChExtent)
  )



return true
}
















const canRelocateOrRemoveExistingMarkupForSelectionRange = (codeMirror) => relocateOrRemoveExistingMarkupForSelectionRange(codeMirror, true)

const relocateOrRemoveExistingMarkupForSelectionRange = (codeMirror, evaluateOnly = false) => {
  let selectionRange = getItemRangeFromSelection(codeMirror)
  const originalSelectionRange = selectionRange

  const markupItems = markupItemsStartingOrEndingInSelectionRange(codeMirror, selectionRange)
  
  selectionRange = getExpandedSelectionRange(codeMirror, markupItems, selectionRange)
  if (!evaluateOnly) {
    codeMirror.setSelection(selectionRange.startLocation, selectionRange.endLocation)
  }

  const markupItemsIntersectingSelection = getMarkupItemsIntersectingSelection(codeMirror, markupItems, selectionRange)

  let markupRangesToMoveAfterSelection = []
  let markupRangesToMoveBeforeSelection = []
  let markupRangesToRemove = []
  markupItemsIntersectingSelection.forEach(item => {
    const startsInside = item.outerRange.startsInsideRange(selectionRange, true)
    const endsInside = item.outerRange.endsInsideRange(selectionRange, true)
    if (!(startsInside === endsInside)) { // XOR
      if (startsInside) {
        markupRangesToMoveAfterSelection.push(item.openingMarkupRange())
      }
      if (endsInside) {
        markupRangesToMoveBeforeSelection.unshift(item.closingMarkupRange())
      }
    } else if (startsInside && endsInside) {
      markupRangesToRemove.push(item.openingMarkupRange())
      markupRangesToRemove.push(item.closingMarkupRange())
    }
  })
  
  const noMarkupToBeMovedToEitherSide = (markupRangesToMoveAfterSelection.length === 0 && markupRangesToMoveBeforeSelection.length === 0)
  if (noMarkupToBeMovedToEitherSide) {
    const openingMarkupRanges = markupItemsIntersectingSelection.map(item => item.openingMarkupRange())
    const closingMarkupRanges = markupItemsIntersectingSelection.map(item => item.closingMarkupRange())
    const allMarkupRanges = openingMarkupRanges.concat(closingMarkupRanges)
    if (evaluateOnly) {
      return allMarkupRanges.length > 0
    }
    removeTextFromRanges(codeMirror, allMarkupRanges)
    return
  }
  if (evaluateOnly) {
    return true
  }

  const accumulatedLeftMarkup = getTextFromRanges(codeMirror, markupRangesToMoveAfterSelection)
  const accumulatedRightMarkup = getTextFromRanges(codeMirror, markupRangesToMoveBeforeSelection)

  // Relocate any markup that needs to be moved after selection
  codeMirror.replaceRange(accumulatedLeftMarkup, selectionRange.endLocation, null, '+')

  // Remove any markup that needs to be blasted
  const allMarkupRangesToRemove = markupRangesToMoveBeforeSelection.concat(markupRangesToMoveAfterSelection).concat(markupRangesToRemove)
  removeTextFromRanges(codeMirror, allMarkupRangesToRemove)

  // Relocate any markup that needs to be moved before selection
  codeMirror.replaceRange(accumulatedRightMarkup, selectionRange.startLocation, null, '+')

  // Adjust selection to account for adjustments made above.
  codeMirror.setSelection(
    selectionRange.startLocation.withOffset(0, accumulatedRightMarkup.length), 
    selectionRange.endLocation.withOffset(0, -getTextFromRanges(codeMirror, markupRangesToMoveAfterSelection.concat(markupRangesToRemove)).length)
  )
}

// Need to remove in reverse order of appearance to avoid invalidating yet-to-be-removed ranges.
const removeTextFromRanges = (codeMirror, ranges) => {
  const reverseSortedRanges = Array.from(ranges).sort((a, b) => {
    return a.startLocation.lessThan(b.startLocation)
  })
  reverseSortedRanges.forEach(range => codeMirror.replaceRange('', range.startLocation, range.endLocation, '+'))
}

const getTextFromRanges = (codeMirror, ranges) => ranges.map(range => codeMirror.getRange(range.startLocation, range.endLocation)).join('')

const getExpandedSelectionRange = (codeMirror, markupItems, selectionRange) => {
  let newSelectionRange = selectionRange
  
  // If selectionRange starts inside a markup item's opening markup, the returned range start will be moved to start of opening markup.
  const selectionStartsInOpeningMarkupOfItem = markupItems.find(item => selectionRange.startsInsideRange(item.openingMarkupRange(), true))
  if (selectionStartsInOpeningMarkupOfItem) {
    newSelectionRange.startLocation = selectionStartsInOpeningMarkupOfItem.openingMarkupRange().startLocation
  } else {
    // If selectionRange starts inside a markup item's closing markup, the returned range start will be moved to end of closing markup.
    const selectionStartsInClosingMarkupOfItem = markupItems.find(item => selectionRange.startsInsideRange(item.closingMarkupRange(), true))
    if (selectionStartsInClosingMarkupOfItem) {
      newSelectionRange.startLocation = selectionStartsInClosingMarkupOfItem.closingMarkupRange().endLocation
    }
  }

  // If selectionRange ends inside a markup item's closing markup, the returned range end will be moved to end of closing markup.
  const selectionEndsInClosingMarkupOfItem = markupItems.find(item => selectionRange.endsInsideRange(item.closingMarkupRange(), true))
  if (selectionEndsInClosingMarkupOfItem) {
    newSelectionRange.endLocation = selectionEndsInClosingMarkupOfItem.closingMarkupRange().endLocation
  } else {
    // If selectionRange ends inside a markup item's opening markup, the returned range end will be moved to start of opening markup.
    const selectionEndsInOpeningMarkupOfItem = markupItems.find(item => selectionRange.endsInsideRange(item.openingMarkupRange(), true))
    if (selectionEndsInOpeningMarkupOfItem) {
      newSelectionRange.endLocation = selectionEndsInOpeningMarkupOfItem.openingMarkupRange().startLocation
    }
  }
  
  return newSelectionRange
}

exports.clearFormatting = clearFormatting
exports.canClearFormatting = canClearFormatting