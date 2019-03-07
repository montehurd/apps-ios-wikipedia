
// Reminder: after we start using broswerify for code mirror bits DRY this up with the `SelectedAndAdjacentText` class in `editTextSelection.js`
class SelectedAndAdjacentText {
  constructor(selectedText, textBeforeSelectedText, textAfterSelectedText) {
    this.selectedText = selectedText
    this.textBeforeSelectedText = textBeforeSelectedText
    this.textAfterSelectedText = textAfterSelectedText
  }
  
  regexForLocatingSelectedTextInWikitext(wikitext) {
    const atLeastOneNonWordPattern = '\\W+'
    const restrictiveRegex = this.regexForLocatingSelectedTextWithPatternForSpace(atLeastOneNonWordPattern)
    if (restrictiveRegex.test(wikitext)) {
        return restrictiveRegex
    }

    const atLeastOneCharPattern = '.+'
    const permissiveRegex = this.regexForLocatingSelectedTextWithPatternForSpace(atLeastOneCharPattern)
    if (permissiveRegex.test(wikitext)) {
        return permissiveRegex
    }
    return null
  }
  
  // Reminder: This object's parameters are always space separated words here.
  regexForLocatingSelectedTextWithPatternForSpace(patternForSpace) {
    const replaceSpaceWith = (s, replacement) => s.replace(/\s+/g, replacement)

    const selectedTextPattern = replaceSpaceWith(this.selectedText, patternForSpace)
    const textBeforeSelectedTextPattern = replaceSpaceWith(this.textBeforeSelectedText, patternForSpace)
    const textAfterSelectedTextPattern = replaceSpaceWith(this.textAfterSelectedText, patternForSpace)

    // Attempt to locate wikitext selection based on the non-wikitext context strings above.
    const beforePattern = textBeforeSelectedTextPattern.length > 0 ? `.*?${textBeforeSelectedTextPattern}.*` : '.*'
    const pattern = `(${beforePattern})(${selectedTextPattern}).*${textAfterSelectedTextPattern}`
    const regex = new RegExp(pattern, 's')

    return regex
  }
}

const wikitextRangeForSelectedTextEditInfo = (selectedAndAdjacentText, wikitext) => {
    const regex = selectedAndAdjacentText.regexForLocatingSelectedTextInWikitext(wikitext)
    if (regex === null) {
      return null
    }
    const match = wikitext.match(regex)
    const matchedWikitextBeforeSelection = match[1]
    const matchedWikitextSelection = match[2]
    const wikitextRange = getWikitextRangeToSelect(matchedWikitextBeforeSelection, matchedWikitextSelection)
    return wikitextRange
}

const getWikitextRangeToSelect = (wikitextBeforeSelection, wikitextSelection) => {
  const wikitextBeforeSelectionLines = wikitextBeforeSelection.split('\n')
  const startLine = wikitextBeforeSelectionLines.length - 1 
  const startCh = wikitextBeforeSelectionLines.pop().length

  const wikitextSelectionLines = wikitextSelection.split('\n')
  const endLine = startLine + wikitextSelectionLines.length - 1
  const endCh = wikitextSelectionLines.pop().length + (startLine === endLine ? startCh : 0)

  let from = {line: startLine, ch: startCh}
  let to = {line: endLine, ch: endCh}
  
  return {from, to}
}

const scrollToAndHighlightRange = (range, codemirror) => {
  let marker = null
  // Temporarily set selection so we can use existing `scrollCursorIntoViewIfNeeded` method to bring the selection on-screen.
  codemirror.setSelection(range.from, range.to)
  setTimeout(() => {
    scrollCursorIntoViewIfNeeded(true)
    marker = codemirror.markText(range.from, range.to, {
      css: 'background-color: rgba(255, 204, 51, 0.4)', // Can use 'className' (vs 'css') if needed.
      clearOnEnter: true,
      inclusiveLeft: true,
      inclusiveRight: true
    })
    /*
    setTimeout(() => {
     marker.clear()
     window.getSelection().removeAllRanges()
    }, 2000)
    */
    setTimeout(() => {
      window.getSelection().removeAllRanges()
    }, 10)
  }, 250)
}

const highlightAndScrollToWikitextForSelectedTextEditInfo = (selectedText, textBeforeSelectedText, textAfterSelectedText) => {
  const wikitext = editor.getValue()
  const selectedAndAdjacentText = new SelectedAndAdjacentText(selectedText, textBeforeSelectedText, textAfterSelectedText)
  const rangeToHighlight = wikitextRangeForSelectedTextEditInfo(selectedAndAdjacentText, wikitext)
  if (rangeToHighlight === null) {
    return null
  }
  scrollToAndHighlightRange(rangeToHighlight, editor)
}