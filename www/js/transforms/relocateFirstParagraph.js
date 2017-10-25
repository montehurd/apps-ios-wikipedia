
function moveFirstGoodParagraphAfterElement(preceedingElementID, content ) {
    /*
    Instead of moving the infobox down beneath the first P tag,
    move the first good looking P tag *up* (as the first child of
    the first section div). That way the first P text will appear not
    only above infoboxes, but above other tables/images etc too!
    */

  if(content.getElementById( 'mainpage' ))return

  var block_0 = content.getElementById( 'content_block_0' )
  if(!block_0) return

  var allPs = block_0.getElementsByTagName( 'p' )
  if(!allPs) return

  var preceedingElement = content.getElementById( preceedingElementID )
  if(!preceedingElement) return

  function isParagraphGood(p) {
    // Narrow down to first P which is direct child of content_block_0 DIV.
    // (Don't want to yank P from somewhere in the middle of a table!)
    if  (p.parentNode == block_0 ||
            /* HAX: the line below is a temporary fix for <div class="mw-mobilefrontend-leadsection"> temporarily
               leaking into mobileview output - as soon as that div is removed the line below will no longer be needed. */
            p.parentNode.className == 'mw-mobilefrontend-leadsection'
            ){
                // Ensure the P being pulled up has at least a couple lines of text.
                // Otherwise silly things like a empty P or P which only contains a
                // BR tag will get pulled up (see articles on "Chemical Reaction" and
                // "Hawaii").
                // Trick for quickly determining element height:
                //      https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement.offsetHeight
                //      http://stackoverflow.com/a/1343350/135557
      var minHeight = 40
      var pIsTooSmall = p.offsetHeight < minHeight
pIsTooSmall = false
      return !pIsTooSmall
    }
    return false

  }

  var firstGoodParagraph = function(){
    return Array.prototype.slice.call( allPs).find(isParagraphGood)
  }()

  if(!firstGoodParagraph) return

  // Move everything between the firstGoodParagraph and the next paragraph to a light-weight fragment.
  var fragmentOfItemsToRelocate = function(){
    var didHitGoodP = false
    var didHitNextP = false

    var shouldElementMoveUp = function(element) {
      if(didHitGoodP && element.tagName === 'P'){
        didHitNextP = true
      }else if(element.isEqualNode(firstGoodParagraph)){
        didHitGoodP = true
      }
      return didHitGoodP && !didHitNextP
    }

    var fragment = document.createDocumentFragment()
    Array.prototype.slice.call(firstGoodParagraph.parentNode.childNodes).forEach(function(element) {
      if(shouldElementMoveUp(element)){
        // appendChild() attaches the element to the fragment *and* removes it from DOM.
        fragment.appendChild(element)
      }
    })
    return fragment
  }()

  // Attach the fragment just after `preceedingElement`.
  // insertBefore() on a fragment inserts "the children of the fragment, not the fragment itself."
  // https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment
  block_0.insertBefore(fragmentOfItemsToRelocate, preceedingElement.nextSibling)
}

exports.moveFirstGoodParagraphAfterElement = moveFirstGoodParagraphAfterElement