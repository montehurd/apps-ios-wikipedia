
const tagMarkupItemsForLineTokens = require('./codemirror-range-determination-tag').tagMarkupItemsForLineTokens
const nonTagMarkupItemsForLineTokens = require('./codemirror-range-determination-non-tag').nonTagMarkupItemsForLineTokens

const markupItemsForLineTokens = (lineTokens) => {
  const tagMarkupItems = tagMarkupItemsForLineTokens(lineTokens)
  const nonTagMarkupItems = nonTagMarkupItemsForLineTokens(lineTokens)
  const markupItems = tagMarkupItems.concat(nonTagMarkupItems)
  return markupItems
}

exports.markupItemsForLineTokens = markupItemsForLineTokens
