// uncomment call to 'showRangeDebuggingButtons()' at bottom to use
const showRangeDebuggingButtons = () => {
  
  var markupItems = []
  var currentItemIndex = 0

  var highlightHandle = null
  var useOuter = true

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

  const addTestingButtons = () => {
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
      flickerTextForMarkupItemAtIndex(currentItemIndex)    
      console.log('next')    
    })

    addButton('<', () => {
      clearHighlightHandle()
      currentItemIndex = currentItemIndex - 1
      if (currentItemIndex < 0) {
        currentItemIndex = 0
      }
      flickerTextForMarkupItemAtIndex(currentItemIndex)    
      console.log('prev')    
    })

    const reset = () => {
      clearHighlightHandle()
      clearItems()    
    }

    const kickoff = () => {
      reset()

//NEW for tags
      // markupItems = tagMarkupItemsForLine(editor.getCursor().line)
//OLD for non-tags
      // markupItems = markupItemsForLine(editor.getCursor().line)
//NEW for non-tags
      markupItems = newNonTagMarkupItemsForLine(editor.getLineTokens(editor.getCursor().line, true))


      flickerTextForMarkupItemAtIndex(currentItemIndex)
    }

    addButton('test outer', () => {
      useOuter = true
      kickoff()
    })

    addButton('test inner', () => {
      useOuter = false
      kickoff()
    })
  }

  const flickerTextForMarkupItemAtIndex = (index) => {
    const line = editor.getCursor().line
    const markupItem = markupItems[index]
    const range = useOuter ? markupItem.outer : markupItem.inner

    clearHighlightHandle()
    highlightHandle = editor.markText({line: line, ch: range.start}, {line: line, ch: range.end}, {
      className: 'testOuter'
    })
  }

  // could inject testing text here too
  setTimeout(addTestingButtons, 2000)
}

showRangeDebuggingButtons()