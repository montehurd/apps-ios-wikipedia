const newEditSectionButton = require('wikimedia-page-library').EditTransform.newEditSectionButton

function addEditButtonAfterElement(preceedingElementSelector, sectionID, content) {
  const preceedingElement = content.querySelector(preceedingElementSelector)
  preceedingElement.parentNode.insertBefore(
    newEditSectionButton(content, sectionID),
    preceedingElement.nextSibling
  )
}

function addEditButtonsToElements(elementsSelector, sectionIDAttribute, content) {
  Array.from(content.querySelectorAll(elementsSelector))
  .forEach(function(element){
    element.appendChild(newEditSectionButton(content, element.getAttribute(sectionIDAttribute)))
  })
}

function addEditButtons(content) {
  // Add lead section edit button after the lead section horizontal rule element.
  addEditButtonAfterElement('#content_block_0_hr', 0, content)
  // Add non-lead section edit buttons inside respective header elements.
  addEditButtonsToElements('.section_heading[data-id]:not([data-id=""]):not([data-id="0"])', 'data-id', content)
}

exports.addEditButtons = addEditButtons