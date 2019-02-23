const markupItemsForLineTokens = require('./codemirror-range-determination').markupItemsForLineTokens

let markupItems = []
let currentItemIndex = 0
let highlightHandle = null
let useOuter = true
let codeMirror = null

const addButton = (title, tapClosure) => {
  const button = document.createElement('button')
  button.innerHTML = title
  document.body.insertBefore(button, document.body.firstChild)
  button.addEventListener ('click', tapClosure)
}

const clearItems = () => {
  markupItems = []
}

const clearHighlightHandle = () => {
  if (highlightHandle) {
    highlightHandle.clear()
  }
  highlightHandle = null
}

const reset = () => {
  clearHighlightHandle()
  clearItems()    
}

const kickoff = () => {
  reset()
  markupItems = markupItemsForLineTokens(codeMirror.getLineTokens(codeMirror.getCursor().line, true))
  highlightTextForMarkupItemAtIndex(currentItemIndex)
}

const rangeDebuggingCSSClassName = 'range-debugging'

function addRangeDebuggingStyleOnce() {
  const id = 'debugging-style-element'
  if (document.getElementById(id)) {
    return
  }
  const cssNode = document.createElement('style')
  cssNode.id = id
  cssNode.innerHTML = `.${rangeDebuggingCSSClassName} { background-color: #cccccc; }`
  document.body.appendChild(cssNode)
}

const showRangeDebuggingButtonsForCursorLine = (cm) => {
  codeMirror = cm
  
  addRangeDebuggingStyleOnce()
  
  addButton('reset', () => {
    reset()
    currentItemIndex = 0
    console.log('reset')    
  })

  addButton('>', () => {
    clearHighlightHandle()
    currentItemIndex = currentItemIndex + 1
    if (currentItemIndex > (markupItems.length - 1)) {
      currentItemIndex = markupItems.length - 1
    }
    highlightTextForMarkupItemAtIndex(currentItemIndex)    
    console.log('next')    
  })

  addButton('<', () => {
    clearHighlightHandle()
    currentItemIndex = currentItemIndex - 1
    if (currentItemIndex < 0) {
      currentItemIndex = 0
    }
    highlightTextForMarkupItemAtIndex(currentItemIndex)    
    console.log('prev')    
  })

  addButton('test outer', () => {
    useOuter = true
    kickoff()
  })

  addButton('test inner', () => {
    useOuter = false
    kickoff()
  })
}

const highlightTextForMarkupItemAtIndex = (index) => {
  const line = codeMirror.getCursor().line
  const markupItem = markupItems[index]
  const range = useOuter ? markupItem.outer : markupItem.inner

  clearHighlightHandle()
  highlightHandle = codeMirror.markText({line: line, ch: range.start}, {line: line, ch: range.end}, {
    className: rangeDebuggingCSSClassName
  })
}

exports.showRangeDebuggingButtonsForCursorLine = showRangeDebuggingButtonsForCursorLine