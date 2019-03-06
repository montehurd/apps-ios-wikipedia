
/*
break out content of highlightAndScrollToTextForSelectedTextEditInfo below
- file called 'CodeMirror-EditSelectionJavascript.js'
- put in www code mirror folder and ensure it gets copied to assets
- reference the file with a script tag above

leave wmf.highlightAndScrollToTextForSelectedTextEditInfo in place, but have it call 2 
methods in the 'CodeMirror-EditSelectionJavascript.js' file:

- highlightRangeForSelectedTextEditInfo
- scrollToAndHighlightRange


- on pr document edge cases from notes.txt (including 1st paragraph relocation issue)

*/


const highlightRangeForSelectedTextEditInfo = (selectedText, textBeforeSelectedText, textAfterSelectedText) => {
    const getWordsOnlyStringForString = (s) => s.replace(/[\W_]+/g, ' ').trim()
    const getWildCardsForNonWords = (s) => s.replace(/[\W_]+/g, '.*?')

    // Adjacent words are used to disambiguate search result.
    const numberOfAdjacentWordsToIncludeInSearch = 2

    const wordsBefore = getWordsOnlyStringForString(textBeforeSelectedText.trim()).split(' ')
      .filter((e, i, a) => (a.length - i - 1) < numberOfAdjacentWordsToIncludeInSearch)

    const wordsAfter = getWordsOnlyStringForString(textAfterSelectedText.trim()).split(' ')
      .filter((e, i) => i < numberOfAdjacentWordsToIncludeInSearch)

    const beforeString = getWildCardsForNonWords(wordsBefore.join(' '))
    const selectionString = getWildCardsForNonWords(getWordsOnlyStringForString(selectedText.trim()))
    const afterString = getWildCardsForNonWords(wordsAfter.join(' '))
    const beforeStringPattern = beforeString.length > 0 ? `.*?${beforeString}.*` : '.*'
    const pattern = `(${beforeStringPattern})(${selectionString}).*${afterString}`
    const regex = new RegExp(pattern, 's')
    const wikitext = editor.getValue()
    const match = wikitext.match(regex)

    const linesBeforeSoughtMatch = match[1].split('\n')
    const startLine = linesBeforeSoughtMatch.length - 1 
    const startCh = linesBeforeSoughtMatch.pop().length

    const linesInSoughtMatch = match[2].split('\n')
    const endLine = startLine + linesInSoughtMatch.length - 1
    const endCh = linesInSoughtMatch.pop().length + (startLine === endLine ? startCh : 0)

    let from = {line: startLine, ch: startCh}
    let to = {line: endLine, ch: endCh}
    
    return {
      from,
      to
    }
}

const scrollToAndHighlightRange = (range) => {
  let marker = null
  editor.setSelection(range.from, range.to)
  setTimeout(() => {
    scrollCursorIntoViewIfNeeded(true)
    marker = editor.markText(range.from, range.to, {
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

const highlightAndScrollToTextForSelectedTextEditInfo = (selectedText, textBeforeSelectedText, textAfterSelectedText) => {
  const rangeToHighlight = highlightRangeForSelectedTextEditInfo(selectedText, textBeforeSelectedText, textAfterSelectedText)
  scrollToAndHighlightRange(rangeToHighlight)
}