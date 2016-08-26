(function () {
var refs = require("./refs");
var utilities = require("./utilities");
var tableCollapser = require("./transforms/collapseTables");

document.onclick = function() {
    // Reminder: resist adding any click/tap handling here - they can
    // "fight" with items in the touchEndedWithoutDragging handler.
    // Add click/tap handling to touchEndedWithoutDragging instead.
    event.preventDefault(); // <-- Do not remove!
};

// track where initial touches start
var touchDownY = 0.0;
document.addEventListener(
            "touchstart",
            function (event) {
                touchDownY = parseInt(event.changedTouches[0].clientY);
            }, false);

function handleTouchEnded(event){
    var touchobj = event.changedTouches[0];
    var touchEndY = parseInt(touchobj.clientY);
    if (((touchDownY - touchEndY) === 0) && (event.changedTouches.length === 1)) {
        // None of our tap events should fire if the user dragged vertically.
        touchEndedWithoutDragging(event);
    }
}

function touchEndedWithoutDragging(event){
    /*
     there are certain elements which don't have an <a> ancestor, so if we fail to find it,
     specify the event's target instead
     */
    var didSendMessage = maybeSendMessageForTarget(event, utilities.findClosest(event.target, 'A') || event.target);

    var hasSelectedText = window.getSelection().rangeCount > 0;

    if (!didSendMessage && !hasSelectedText) {
        // Do NOT prevent default behavior -- this is needed to for instance
        // handle deselection of text.
        window.webkit.messageHandlers.nonAnchorTouchEndedWithoutDragging.postMessage({
                                                  id: event.target.getAttribute( "id" ),
                                                  tagName: event.target.tagName,
                                                  clientX: event.changedTouches[0].clientX,
                                                  clientY: event.changedTouches[0].clientY
                                                  });

    }
}

/**
 * Attempts to send message which corresponds to `hrefTarget`, based on various attributes.
 * @return `true` if a message was sent, otherwise `false`.
 */
function maybeSendMessageForTarget(event, hrefTarget){
    if (!hrefTarget) {
        return false;
    }
    var href = hrefTarget.getAttribute( "href" );
    var hrefClass = hrefTarget.getAttribute('class');
    if (hrefTarget.getAttribute( "data-action" ) === "edit_section") {
        window.webkit.messageHandlers.editClicked.postMessage({ sectionId: hrefTarget.getAttribute( "data-id" ) });
    } else if (href && refs.isCitation(href)) {
        // Handle reference links with a popup view instead of scrolling about!
        refs.sendNearbyReferences( hrefTarget );
    } else if (href && href[0] === "#") {
 
        tableCollapser.openCollapsedTableIfItContainsElement(document.getElementById(href.substring(1)));
 
        // If it is a link to an anchor in the current page, use existing link handling
        // so top floating native header height can be taken into account by the regular
        // fragment handling logic.
        window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href });
    } else if (typeof hrefClass === 'string' && hrefClass.indexOf('image') !== -1) {
         window.webkit.messageHandlers.imageClicked.postMessage({
                                                          'src': event.target.getAttribute('src'),
                                                          'width': event.target.naturalWidth,   // Image should be fetched by time it is tapped, so naturalWidth and height should be available.
                                                          'height': event.target.naturalHeight,
 														  'data-file-width': event.target.getAttribute('data-file-width'),
 														  'data-file-height': event.target.getAttribute('data-file-height')
                                                          });
    } else if (href) {
        window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href });
    } else {
        return false;
    }
    return true;
}

document.addEventListener("touchend", handleTouchEnded, false);

 function shouldPeekElement(element){
    return (element.tagName == "IMG" || (element.tagName == "A" && !refs.isReference(element.href) && !refs.isCitation(element.href) && !refs.isEndnote(element.href)));
 }
 
 // 3D Touch peeking listeners.
 document.addEventListener("touchstart", function (event) {
                           // Send message with url (if any) from touch element to native land.
                           var element = window.wmf.elementLocation.getElementFromPoint(event.changedTouches[0].pageX, event.changedTouches[0].pageY);
                           if(shouldPeekElement(element)){
                               window.webkit.messageHandlers.peek.postMessage({
                                                                              'tagName': element.tagName,
                                                                              'href': element.href,
                                                                              'src': element.src
                                                                              });
                           }
                           }, false);
 
 document.addEventListener("touchend", function () {
                           // Tell native land to clear the url - important.
                           window.webkit.messageHandlers.peek.postMessage({});
                           }, false);
})();
