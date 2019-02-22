
const intersection = (a, b) => new Set([...a].filter(x => b.has(x)))
const difference = (a, b) => new Set([...a].filter(x => !b.has(x)))
const union = (a, b) => new Set([...a, ...b])




class MarkupItem {
  constructor(item, inner, outer) {
    this.item = item
    this.inner = inner
    this.outer = outer
  }
  name() {
    if (this.item === 'mw-apostrophes-bold') {
        return 'bold'
    }
    if (this.item === 'mw-section-header') {
        return 'header'
    }
    if (this.item === 'mw-link-bracket') {
        return 'link'
    }
    if (this.item === 'mw-template-bracket') {
        return 'template'
    }
    if (this.item === 'mw-apostrophes-italic') {
        return 'italic'
    }
    return this.item
  }  
  isComplete() {
    return this.inner.isComplete() && this.outer.isComplete()
  }
}

class ItemRange {
  constructor(start, end) {
    this.start = start
    this.end = end
  }
  isComplete() {
    return this.start !== -1 && this.end !== -1
  }
}




const isTokenForTagBracket = (token) => tokenIncludesType(token, 'mw-htmltag-bracket') || tokenIncludesType(token, 'mw-exttag-bracket')
const isTokenStartOfOpenTag = (token) => isTokenForTagBracket(token) && token.string === '<'
const isTokenStartOfCloseTag = (token) => isTokenForTagBracket(token) && token.string === '</'  




const getOpenTagStartTokenIndices = (lineTokens) => {
  let openTagStartTokenIndices = []
  const possiblyRecordOpenTagTokenIndex = (token, index) => {
    if (isTokenStartOfOpenTag(token)) {
      openTagStartTokenIndices.push(index)
    }
  }
  lineTokens.forEach(possiblyRecordOpenTagTokenIndex)
  return openTagStartTokenIndices
}


const tagMarkupItemsForLineTokens = (lineTokens) => {
  const openTagStartTokenIndices = getOpenTagStartTokenIndices(lineTokens)    
  const openTagEndTokenIndices = openTagStartTokenIndices.map(i => i + 2)
  const tagTypeTokenIndices = openTagStartTokenIndices.map(i => i + 1)
  const closeTagStartTokenIndices = getCloseTagStartTokenIndices(lineTokens, openTagStartTokenIndices)    
  const closeTagEndTokenIndices = closeTagStartTokenIndices.map(i => i + 2)

  let output = []
  const tagCount = openTagStartTokenIndices.length
  
  for (let i = 0; i < tagCount; i++) { 
    const openTagStartTokenIndex = openTagStartTokenIndices[i]
    const tagTypeTokenIndex = tagTypeTokenIndices[i]
    const openTagEndTokenIndex = openTagEndTokenIndices[i]
    const closeTagStartTokenIndex = closeTagStartTokenIndices[i]
    const closeTagEndTokenIndex = closeTagEndTokenIndices[i]

    let outer = new ItemRange(lineTokens[openTagStartTokenIndex].start, lineTokens[closeTagEndTokenIndex].end)
    let inner = new ItemRange(lineTokens[openTagEndTokenIndex].end, lineTokens[closeTagStartTokenIndex].start)
    let tag = lineTokens[tagTypeTokenIndex].string.trim()
    output.push(new MarkupItem(tag, inner, outer))
  }
  return output
}


const getCloseTagStartTokenIndices = (lineTokens, openTagStartTokenIndices) => {
  let closeTagStartTokenIndices = []
  
  openTagStartTokenIndices.forEach(startOfOpenTagTokenIndex => {
    let depth = 0
    for (let i = startOfOpenTagTokenIndex + 1; i < lineTokens.length; i++) { 
      let thisToken = lineTokens[i]
      if (isTokenStartOfOpenTag(thisToken)){
        depth = depth + 1
      } else if (isTokenStartOfCloseTag(thisToken)) {
        if (depth === 0) {
          closeTagStartTokenIndices.push(i)
          break
        }
        depth = depth - 1        
      }
    }
    
  })
  
  return closeTagStartTokenIndices
}



















// - returns set of types for token
// - smooths out inconsistent nested bold and italic types
const tokenTypes = (token) => {
  const types = (token.type || '')
    .trim()
    .split(' ')
    .filter(s => s.length > 0)
    .map(s => {
      // the parser fails to add 'mw-apostrophes-bold' for nested bold (it only adds 'mw-apostrophes')
      if (s === 'mw-apostrophes' && token.string === `'''`) {
        return 'mw-apostrophes-bold'
      }
      // the parser fails to add 'mw-apostrophes-italic' for nested italic (it only adds 'mw-apostrophes')
      if (s === 'mw-apostrophes' && token.string === `''`) {
        return 'mw-apostrophes-italic'
      }
      return s
    })

  return new Set(types)
}


const nonTagMarkupItemsForLineTokens = (lineTokens) => {
  const soughtTokenTypes = new Set(['mw-apostrophes-bold', 'mw-apostrophes-italic', 'mw-link-bracket', 'mw-section-header', 'mw-template-bracket'])  

  let trackedTypes = new Set()
  let outputMarkupItems = []
  
  const tokenWithEnrichedInHtmlTagArray = (token, index, tokens) => {
    
    const types = intersection(tokenTypes(token), soughtTokenTypes)
    
    const typesToStopTracking = Array.from(intersection(trackedTypes, types))
    const typesToStartTracking = Array.from(difference(types, trackedTypes))
    
    const addMarkupItemWithRangeStarts = (type) => {
      const inner = new ItemRange(token.end, -1) 
      const outer = new ItemRange(token.start, -1) 
      const markupItem = new MarkupItem(type, inner, outer)
      outputMarkupItems.push(markupItem)
    }
    
    const updateMarkupItemRangeEnds = (type) => {
      const markupItem = outputMarkupItems.find(markupItem => {
        return markupItem.item === type && !markupItem.isComplete()
      })
      if (markupItem) {
        markupItem.inner.end = token.start
        markupItem.outer.end = token.end
      }
    }
    
    typesToStartTracking.forEach(addMarkupItemWithRangeStarts)
    typesToStopTracking.forEach(updateMarkupItemRangeEnds)
    
    typesToStopTracking.forEach(tag => trackedTypes.delete(tag))
    typesToStartTracking.forEach(tag => trackedTypes.add(tag))
  }
  
  lineTokens.forEach(tokenWithEnrichedInHtmlTagArray)    
  return outputMarkupItems
}










const markupItemsForLine = (line) => {
  const lineTokens = editor.getLineTokens(line, true)
  const tagMarkupItems = tagMarkupItemsForLineTokens(lineTokens)
  const nonTagMarkupItems = nonTagMarkupItemsForLineTokens(lineTokens)
  const markupItems = tagMarkupItems.concat(nonTagMarkupItems)
  const markupItemsWithNames = markupItems.map(i => {
    i.item = i.name()
    return i
  })
  return markupItemsWithNames
}



