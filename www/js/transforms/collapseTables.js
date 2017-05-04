const collapseTable = require('wikimedia-page-library').CollapseTable;
//const elementUtilities = require('wikimedia-page-library').ElementUtilities;
var utilities = require("../utilities");

function footerDivClickCallback(container) {
  window.scrollTo( 0, container.offsetTop - 10 );
}

function hideTables(content, isMainPage, pageTitle, infoboxTitle, otherTitle, footerTitle) {
  collapseTable.collapseTables(document, content, pageTitle, isMainPage, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback);
}

exports.openCollapsedTableIfItContainsElement = function(element){
    if(element){
//var container = elementUtilities.findClosestAncestor(element, "[class*='app_table_container']");
var container = utilities.findClosest(element, "[class*='app_table_container']");
        if(container){
            var collapsedDiv = container.firstChild;
            if(collapsedDiv && collapsedDiv.classList.contains('app_table_collapsed_open')){
                collapsedDiv.click();
            }
        }
    }
};

exports.hideTables = hideTables;
