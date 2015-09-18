(function () {
var bridge = require("./bridge");
var transformer = require("./transformer");
var refs = require("./refs");
var issuesAndDisambig = require("./transforms/collapsePageIssuesAndDisambig");
var utilities = require("./utilities");

// DOMContentLoaded fires before window.onload! That's good!
// See: http://stackoverflow.com/a/3698214/135557
document.addEventListener("DOMContentLoaded", function() {


//    transformer.transform( "moveFirstGoodParagraphUp", document );
//    transformer.transform( "hideRedlinks", document );
//    transformer.transform( "addImageOverflowXContainers", document ); // Needs to happen before "widenImages" transform.
//    transformer.transform( "widenImages", document );
//    transformer.transform( "hideTables", document );
//    transformer.transform( "collapsePageIssuesAndDisambig", document.getElementById( "section_heading_and_content_block_0" ) );





    // Identify 1st good paragraph before detaching
    // (p tags don't have offsetHeight used to determine "goodness" after detach)
    transformer.transform( "markFirstGoodParagraph", document );

    // Now detach so we can do dom transforms without layout thrashing
    var content = document.getElementById("content");
    var parent = content.parentNode;
    var detachedContent = parent.removeChild(content);
    
    transformer.transform( "moveFirstGoodParagraphUp", detachedContent );
    transformer.transform( "hideRedlinks", detachedContent );
    transformer.transform( "disableFilePageEdit", detachedContent );
    transformer.transform( "addImageOverflowXContainers", detachedContent ); // Needs to happen before "widenImages" transform.



/*

Needed to finish making the remainder of transforms able to operate on detachedContent:

    - pass them detachedContent not body
    - make them internally use querySelector and querySelectorAll instead of getElementById and getElementByTagName
    - widenImages would need to change to set the img tag width and height attributes *before* the image load event fires
        (would need to determine width to be requested and extrapolate height from the
        data-file-width/data-file-height ratio)

*/

//    transformer.transform( "widenImages", body );
//    transformer.transform( "hideTables", body );
//    transformer.transform( "collapsePageIssuesAndDisambig", document.getElementById( "section_heading_and_content_block_0" ) );







    // Now reattach the dom so we can see our transforms.
    parent.appendChild(detachedContent);










    bridge.sendMessage( "DOMContentLoaded", {} );
});

bridge.registerListener( "setLanguage", function( payload ){
    var html = document.querySelector( "html" );
    html.lang = payload.lang;
    html.dir = payload.dir;
    html.classList.add( 'content-' + payload.dir );
    html.classList.add( 'ui-' + payload.uidir );
    document.querySelector('base').href = 'https://' + payload.lang + '.wikipedia.org/';
} );

bridge.registerListener( "setPageProtected", function() {
    document.getElementsByTagName( "html" )[0].classList.add( "page-protected" );
} );

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
        bridge.sendMessage('nonAnchorTouchEndedWithoutDragging', {
                              id: event.target.getAttribute( "id" ),
                              tagName: event.target.tagName
                          });

    }
}

/**
 * Attempts to send a bridge message which corresponds to `hrefTarget`, based on various attributes.
 * @return `true` if a message was sent, otherwise `false`.
 */
function maybeSendMessageForTarget(event, hrefTarget){
    if (!hrefTarget) {
        return false;
    }
    var href = hrefTarget.getAttribute( "href" );
    var hrefClass = hrefTarget.getAttribute('class');
    if (href && refs.isReference(href)) {
        // Handle reference links with a popup view instead of scrolling about!
        refs.sendNearbyReferences( hrefTarget );
    } else if (href && href[0] === "#") {
        var targetId = href.slice(1);
        if ( "issues" === targetId ) {
            var issuesPayload = issuesAndDisambig.issuesClicked( hrefTarget );
            bridge.sendMessage( 'issuesClicked', issuesPayload );
        } else if ( "disambig" === targetId ) {
            var disambigPayload = issuesAndDisambig.disambigClicked( hrefTarget );
            bridge.sendMessage( 'disambigClicked', disambigPayload );
        } else if ( "issues_container_close_button" === targetId ) {
            issuesAndDisambig.closeClicked();
        } else {
            // If it is a link to an anchor in the current page, use existing link handling
            // so top floating native header height can be taken into account by the regular
            // fragment handling logic.
            bridge.sendMessage( 'linkClicked', { 'href': href });
        }
    } else if (typeof hrefClass === 'string' && hrefClass.indexOf('image') !== -1) {
         var url = event.target.getAttribute('src');
        bridge.sendMessage('imageClicked', { 'url': url });
    } else if (href) {
        bridge.sendMessage( 'linkClicked', { 'href': href });
    } else {
        return false;
    }
    return true;
}

document.addEventListener("touchend", handleTouchEnded, false);

})();
