// const ItemRange = require('./codemirror-range-objects').ItemRange
// const ItemLocation = require('./codemirror-range-objects').ItemLocation




editor.on('cursorActivity', (doc) => {
console.log('wa')
/*
  sendNativeMessages(doc)

  clearTimeout(cursorActivityScrollTimer)
  cursorActivityScrollTimer = setTimeout(() => {
    scrollCursorIntoViewIfNeeded()        
  }, 25)
*/
})


/*
const rangesIntersect = (range1, range2) => {
  if (range1.start > range2.start + (range2.end - range2.start)) return false
  if (range2.start > range1.start + (range1.end - range1.start)) return false
  // const isSelected = ((Math.abs(range1.start - range1.end) > 0) && (Math.abs(range2.start - range2.end) > 0))
  // if ((range1.start === range2.end) || (range1.end === range2.start) && isSelected) return false
  return true
}

const getSelectionRange = (doc) => {
  const fromCursor = doc.getCursor('from')
  const toCursor = doc.getCursor('to')

  const start = fromCursor.ch
  const end = toCursor.ch
  const isSingleLine = (fromCursor.line === toCursor.line)
  const line = fromCursor.line
  const isRangeSelected = !isSingleLine || (end - start) > 0

  return {
    start,
    end,
    isSingleLine,
    line,
    isRangeSelected
  }
}

const tokensIntersectingSelection = (selectionRange, lineTokens) => {
  return lineTokens
    .filter(token => {
      return rangesIntersect(selectionRange, token)
    })
}
*/




// class ItemRange {
//   constructor(startLocation, endLocation) {
//     this.startLocation = startLocation
//     this.endLocation = endLocation
//   }
//   isComplete() {
//     return this.startLocation.isComplete() && this.endLocation.isComplete()
//   }
// }
// 
// class ItemLocation {
//   constructor(line, ch) {
//     this.line = line
//     this.ch = ch
//   }
//   isComplete() {
//     return this.line !== -1 && this.ch !== -1
//   }
// }
