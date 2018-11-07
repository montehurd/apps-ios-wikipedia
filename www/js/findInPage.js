// Based on the excellent blog post:
// http://www.icab.de/blog/2010/01/12/search-and-highlight-text-in-uiwebview/

let FindInPageResultCount = 0
let FindInPageResultMatches = []
let FindInPagePreviousFocusMatchSpanId = null

const rectContainsRect = (a, b) => a.left <= b.right && b.left <= a.right && a.top <= b.bottom && b.top <= a.bottom

const recursivelyHighlightSearchTermInTextNodesStartingWithElement = (element, searchTerm) => {
  if (element) {
    if (element.nodeType == 3) {            // Text node
      while (true) {
        const value = element.nodeValue  // Search for searchTerm in text node
        const idx = value.toLowerCase().indexOf(searchTerm)



/*
// Use range based appoach instead so we don't unnecessarily add spans which have to be removed later?
// would i need to keep an array of ranges so they could be detatched easily later?
        var range = document.createRange()
        range.setStart(element, idx)
        range.setEnd(element, searchTerm.length)
        const rect = range.getBoundingClientRect()
        if(rect.width > 0 && rect.height > 0){

          const matchIsActuallyOnscreen = rectContainsRect(range.getBoundingClientRect(), element.getBoundingClientRect())
          if(!matchIsActuallyOnscreen){
            break
          }
          // var span2 = document.createElement('span')
          // span2.style.backgroundColor = 'red'
          // range.surroundContents(span2)
        }
        range.detach()
*/



        if (idx < 0) break

        const span = document.createElement('span')
        let text = document.createTextNode(value.substr(idx, searchTerm.length))
        span.appendChild(text)
        span.setAttribute('class', 'findInPageMatch')

        text = document.createTextNode(value.substr(idx + searchTerm.length))
        element.deleteData(idx, value.length - idx)
        const next = element.nextSibling
        element.parentNode.insertBefore(span, next)
        element.parentNode.insertBefore(text, next)
        element = text
/*
//BAD because causes doc reflows! (search for 'a' on obama article)
        // Text node elements with 'text-overflow: ellipsis;' can truncate text. So we need a way to
        // detect if a match is in elided text - i.e. after the ellipsis and thus not visible. By
        // waiting until here where we've added a span around the match we can check if the match
        // span's rect is contained by its parent element's rect - if so it's visible, otherwise we
        // don't actually want to highlight the match.
        const matchIsActuallyOnscreen = rectContainsRect(span.getBoundingClientRect(), span.parentElement.getBoundingClientRect())
        if (!matchIsActuallyOnscreen) {
          const text = span.removeChild(span.firstChild)
          span.parentNode.insertBefore(text, span)
          span.parentNode.removeChild(span)
          break
        }
*/
        FindInPageResultCount++
      }
    } else if (element.nodeType == 1) {     // Element node

      // Offset width and height are also checked so we can detect if element is hidden because its *parent* is hidden.
//BAD cause offset width and height access can be expensive!
      const isOnscreen = element.style.display != 'none' // && element.offsetWidth > 0 && element.offsetHeight > 0

      if (isOnscreen && element.nodeName.toLowerCase() != 'select') {
        for (let i = element.childNodes.length - 1; i >= 0; i--) {
          recursivelyHighlightSearchTermInTextNodesStartingWithElement(element.childNodes[i], searchTerm)
        }
      }
    }
  }
}

const recursivelyRemoveSearchTermHighlightsStartingWithElement = element => {
  if (element) {
    if (element.nodeType == 1) {
      if (element.getAttribute('class') == 'findInPageMatch') {
        const text = element.removeChild(element.firstChild)
        element.parentNode.insertBefore(text, element)
        element.parentNode.removeChild(element)
        return true
      }
      let normalize = false
      for (let i = element.childNodes.length - 1; i >= 0; i--) {
        if (recursivelyRemoveSearchTermHighlightsStartingWithElement(element.childNodes[i])) {
          normalize = true
        }
      }
      if (normalize) {
        element.normalize()
      }

    }
  }
  return false
}

const deFocusPreviouslyFocusedSpan = () => {
  if(FindInPagePreviousFocusMatchSpanId){
    document.getElementById(FindInPagePreviousFocusMatchSpanId).classList.remove('findInPageMatch_Focus')
    FindInPagePreviousFocusMatchSpanId = null
  }
}

const removeSearchTermHighlights = () => {
  FindInPageResultCount = 0
  FindInPageResultMatches = []
  deFocusPreviouslyFocusedSpan()
  recursivelyRemoveSearchTermHighlightsStartingWithElement(document.body)
}

const findAndHighlightAllMatchesForSearchTerm = searchTerm => {
  removeSearchTermHighlights()
  if (searchTerm.trim().length === 0){
    window.webkit.messageHandlers.findInPageMatchesFound.postMessage(FindInPageResultMatches)
    return
  }
  searchTerm = searchTerm.trim()

  recursivelyHighlightSearchTermInTextNodesStartingWithElement(document.body, searchTerm.toLowerCase())

  // The recursion doesn't walk a first-to-last path, so it doesn't encounter the
  // matches in first-to-last order. We can work around this by adding the "id"
  // and building our results array *after* the recursion is done, thanks to
  // "getElementsByClassName".
  const orderedMatchElements = document.getElementsByClassName('findInPageMatch')
  FindInPageResultMatches.length = orderedMatchElements.length
  for (let i = 0; i < orderedMatchElements.length; i++) {
    const matchSpanId = 'findInPageMatchID|' + i
    orderedMatchElements[i].setAttribute('id', matchSpanId)
    // For now our results message to native land will be just an array of match span ids.
    FindInPageResultMatches[i] = matchSpanId
  }

  window.webkit.messageHandlers.findInPageMatchesFound.postMessage(FindInPageResultMatches)
}

const useFocusStyleForHighlightedSearchTermWithId = id => {
  deFocusPreviouslyFocusedSpan()
  setTimeout(() => {
    document.getElementById(id).classList.add('findInPageMatch_Focus')
    FindInPagePreviousFocusMatchSpanId = id
  }, 0)
}

exports.findAndHighlightAllMatchesForSearchTerm = findAndHighlightAllMatchesForSearchTerm
exports.useFocusStyleForHighlightedSearchTermWithId = useFocusStyleForHighlightedSearchTermWithId
exports.removeSearchTermHighlights = removeSearchTermHighlights