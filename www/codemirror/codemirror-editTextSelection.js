
const wikitextRegexForSelectedTextEditInfo = (selectedText, textBeforeSelectedText, textAfterSelectedText) => {
    const getWildCardsForNonWords = (s) => s.replace(/[\W]+/g, '[\\W]+')

    const selectionString = getWildCardsForNonWords(selectedText)
    const beforeString = getWildCardsForNonWords(textBeforeSelectedText)
    const afterString = getWildCardsForNonWords(textAfterSelectedText)

    // Attempt to locate wikitext selection based on the non-wikitext context strings above.
    const beforeStringPattern = beforeString.length > 0 ? `.*?${beforeString}.*` : '.*'
    const pattern = `(${beforeStringPattern})(${selectionString}).*${afterString}`
    const regex = new RegExp(pattern, 's')

    return regex
}

const wikitextRangeForSelectedTextEditInfo = (selectedText, textBeforeSelectedText, textAfterSelectedText, wikitext) => {
    const regex = wikitextRegexForSelectedTextEditInfo(selectedText, textBeforeSelectedText, textAfterSelectedText)
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
  const rangeToHighlight = wikitextRangeForSelectedTextEditInfo(selectedText, textBeforeSelectedText, textAfterSelectedText, wikitext)
  scrollToAndHighlightRange(rangeToHighlight, editor)
}