
// Reduce SelectedTextEditInfo to words only and only keep a couple words before and after.
// QUESTION: should this logic move to the code which extracts these strings so we don't relay unneeded things?
const reduceSelectedTextEditInfo = (selectedText, textBeforeSelectedText, textAfterSelectedText) => {
  const getWordsOnlyStringForString = (s) => s.replace(/[\W]+/g, ' ').trim()

  // Adjacent words are used to disambiguate search result.
  const numberOfAdjacentWordsToIncludeInSearch = 2

  // Keep only the last 'numberOfAdjacentWordsToIncludeInSearch' words of 'textBeforeSelectedText'
  const shouldKeepWordBeforeSelection = (e, i, a) => (a.length - i - 1) < numberOfAdjacentWordsToIncludeInSearch
  const reducedTextBeforeSelectedText = getWordsOnlyStringForString(textBeforeSelectedText.trim())
    .split(' ')
    .filter(shouldKeepWordBeforeSelection)
    .join(' ')
  
  const reducedSelectedText = getWordsOnlyStringForString(selectedText.trim())
  
  // Keep only the first 'numberOfAdjacentWordsToIncludeInSearch' words of 'textAfterSelectedText'
  const shouldKeepWordAfterSelection = (e, i) => i < numberOfAdjacentWordsToIncludeInSearch
  const reducedTextAfterSelectedText = getWordsOnlyStringForString(textAfterSelectedText.trim())
    .split(' ')
    .filter(shouldKeepWordAfterSelection)
    .join(' ')
  
  return {
    textBeforeSelectedText: reducedTextBeforeSelectedText,
    selectedText: reducedSelectedText,
    textAfterSelectedText: reducedTextAfterSelectedText
  }
}

const wikitextRegexForSelectedTextEditInfo = (selectedText, textBeforeSelectedText, textAfterSelectedText) => {
    const reducedSelectedTextEditInfo = reduceSelectedTextEditInfo(selectedText, textBeforeSelectedText, textAfterSelectedText)

    const getWildCardsForNonWords = (s) => s.replace(/[\W]+/g, '[\\W]+')

    const beforeString = getWildCardsForNonWords(reducedSelectedTextEditInfo.textBeforeSelectedText)
    const selectionString = getWildCardsForNonWords(reducedSelectedTextEditInfo.selectedText)
    const afterString = getWildCardsForNonWords(reducedSelectedTextEditInfo.textAfterSelectedText)

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