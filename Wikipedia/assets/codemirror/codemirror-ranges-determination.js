
const intersection = (a, b) => new Set([...a].filter(x => b.has(x)))
const difference = (a, b) => new Set([...a].filter(x => !b.has(x)))
const union = (a, b) => new Set([...a, ...b])
 

// alternate 'enrichment' approach moves type ' em' etc into 'InHtmlTag' - that way completeTagRangesForLineTokens
// can work for non-tag based items
// completeTagRangesForLineTokens(enrichedLineTokens(editor, 26).map(token => { if(token.type === null){ return token}; token.state.InHtmlTag = [token.type.trim()]; return token}))


// TODO: 
// - should i add our own 'InType' instead of using 'InHtmlTag'?
// - handle headings
// - handle multi-line (do separately from the link token logic - only for multi-line capable tags - which ones?)
// - instead of just 'start' and 'end', return an 'inner' and 'outer' start and end so we can easily know how to select contents or contents with wrapping or even remove wrapping
// - write method for getting inner string and outer string
// - write method for removing wrapping (just replace outer string with inner string!)
// - rename completeTagRangesForLineTokens (won't be tag specific when we're done with it)
// - remove unused bits! signatures? indenting? 
// - split out to separate files!
// - add tests!
// - handle html comments <!--h a-->
// - bug: string below. tags after bold don't have range correctly determined. before works. also bug on 6.2
//      a '''bbb''' ccc <u>ddd</u>

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

// - loops through line tokens
// - looks for types of 'mw-apostrophes-bold', 'mw-apostrophes-italic', or 'mw-link-bracket'
// - adds respective type above to each token's 'InHtmlTag' array which is part of the range of the respective type
// - ie adds 'mw-apostrophes-bold' to each token (to its 'InHtmlTag' array) which part of the bolded range
// - needed because the parser isn't consistent with how it populates 'InHtmlTag'
const enrichedLineTokens2 = (lineTokens) => {
  let trackedTypes = new Set()
    
  const tokenWithEnrichedInHtmlTagArray = (token, index, tokens) => {
    const soughtTokenTypes = new Set(['mw-apostrophes-bold', 'mw-apostrophes-italic', 'mw-link-bracket', 'mw-section-header', 'mw-template-bracket'])

    const types = intersection(tokenTypes(token), soughtTokenTypes)
    
    const tagsToStopTracking = Array.from(intersection(trackedTypes, types))
    const tagsToStartTracking = Array.from(difference(types, trackedTypes))
    
    tagsToStopTracking.forEach(tag => trackedTypes.delete(tag))
    tagsToStartTracking.forEach(tag => trackedTypes.add(tag))

    token.state.InHtmlTag = Array.from(union(trackedTypes, new Set(token.state.InHtmlTag)))

    return token
  }

  return lineTokens.map(tokenWithEnrichedInHtmlTagArray)
}





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
    // if (this.item === 'mw-apostrophes-bold') {
    //     return 'bold'
    // }
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




    // Individual words within a tag are tokenized separately, this method 
    // gives us the overall range for the entire tag's contents. Makes it
    // easier see what tags the current selection intersects and also makes
    // it easier to expand selection later to encompass entire tag contents.
    /*
      - loops through line tokens
      - each time it encounters a tag it's not already tracking, it records start
      - until it encounters token w/o that tracked tag, at which point it records end and stops tracking that tag
      - end result will be array of ranges for all tags encountered (can be more that one for a given tag)
      - returns array similar to:
        [
          sup: {start: 12, end: 25},
          small: {start: 32, end: 98},
          large: {start: 12, end: 108},
          small: {start: 100, end: 102}
        ]
      - This is *vastly* simpler to use than large numbers of line tokens.
      - then we can easily set this all encompassing range in the button payload for tags
        (will just need to loop through this array with selection range )
    */
    const markupItemsForLineTokens = (lineTokens) => {
     
      let trackedTags = new Set()
      let markupItems = []
      
      const startAndStopTrackingMarkupItemsInToken = (token, index, tokens) => {
        const tags = new Set(token.state.InHtmlTag)
/*        
        // Fix for tags like 'ref', which mediawiki parsing curiously 
        // doesn't treat like other tags.
        if (token.state.extName !== false) {
          tags.add(token.state.extName)
        }
        
        // Fix for nested tags.
        if (token.state.extState !== false) {
          token.state.extState.InHtmlTag.forEach(tags.add, tags)
        }
*/
        const isNotAlreadyTrackingTag = (tag) => {
          return !trackedTags.has(tag)
        }
        
        // Add tag item to markupItems (with `start` value and placeholder `end` value) 
        // when we first encounter one. Also adds tag to trackedTags.
        const startTrackingTag = (tag) => {
          trackedTags.add(tag)

          let inner = new ItemRange(token.end, -1)
          let outer = new ItemRange(-1, -1)
          if (tokenIncludesType(token, 'mw-htmltag-bracket') || tokenIncludesType(token, 'mw-exttag-bracket')) {
            outer.start = tokens[index - 2].start
          } else {
            outer.start = token.start  
          }

          markupItems.push(new MarkupItem(tag, inner, outer))
        }
        
        [...tags]
          .filter(isNotAlreadyTrackingTag)
          .forEach(startTrackingTag)

        let tagsToStopTracking = new Set()
        
        // Update tagRange `end` when we're no longer part of a trackedTag
        // (also removes tag from trackedTags)
        const stopTrackingTag = (tag) => {
          const prevToken = tokens[index - 1]
          const end = prevToken.end
          let existingRange = markupItems.find(tagRange => {
            return tagRange.item === tag && tagRange.inner.end === -1
          })
          existingRange.inner.end = end

          if (tokenIncludesType(token, 'mw-htmltag-bracket') || tokenIncludesType(token, 'mw-exttag-bracket')) {
            existingRange.outer.end = tokens[index + 2].end
          } else {
            existingRange.outer.end = token.end
          }

          tagsToStopTracking.add(tag)
        }
        
        const shouldStopTrackingTag = (tag) => {
          return !tags.has(tag)
        }
        
        [...trackedTags]
          .filter(shouldStopTrackingTag)
          .forEach(stopTrackingTag)
        
        tagsToStopTracking.forEach(trackedTags.delete, trackedTags)
      }
      
      lineTokens.forEach(startAndStopTrackingMarkupItemsInToken)

      return markupItems.filter(markupItem => markupItem.isComplete())
    }




const markupItemsForLine = (line) => {
  const replaceItemWithName = (markupItem) => {
    markupItem.item = markupItem.name()
    return markupItem
  }  
  return markupItemsForLineTokens(enrichedLineTokens2(editor.getLineTokens(line, true)))
    .map(replaceItemWithName)
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


const tagMarkupItemsForLine = (line) => {

  const lineTokens = editor.getLineTokens(line, true)
  
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
    let tag = lineTokens[tagTypeTokenIndex].string
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
























const newNonTagMarkupItemsForLine = (lineTokens) => {
  let trackedTypes = new Set()
  const soughtTokenTypes = new Set(['mw-apostrophes-bold', 'mw-apostrophes-italic', 'mw-link-bracket', 'mw-section-header', 'mw-template-bracket'])
  
// TODO: rename this so it makes clear this is only for things that cant be nested inside themselves
// - see if 'mw-template-bracket' has a nesting problem...
// - later ensure new methods for unwrapping are not greedy if item is nested inside other item of same type!

let markupItems = []

  const tokenWithEnrichedInHtmlTagArray = (token, index, tokens) => {
    const types = intersection(tokenTypes(token), soughtTokenTypes)
    
    const tagsToStopTracking = Array.from(intersection(trackedTypes, types))
    const tagsToStartTracking = Array.from(difference(types, trackedTypes))

    
tagsToStartTracking.forEach(tag => {
  const inner = new ItemRange(token.end, -1) 
  const outer = new ItemRange(token.start, -1) 
  const markupItem = new MarkupItem(tag, inner, outer)
  markupItems.push(markupItem)
})

tagsToStopTracking.forEach(tag => {
  const markupItem = markupItems.find(markupItem => markupItem.item === tag)
  if (markupItem) {
    markupItem.inner.end = token.start
    markupItem.outer.end = token.end
  }
})
  
    tagsToStopTracking.forEach(tag => trackedTypes.delete(tag))
    tagsToStartTracking.forEach(tag => trackedTypes.add(tag))
  }

  lineTokens.forEach(tokenWithEnrichedInHtmlTagArray)
    
  return markupItems
}
