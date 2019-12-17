/**
 * Accessing Parsoid output
 */

'use strict';

const domUtil = require('./domUtil');
const mUtil = require('./mobile-util');

const api = require('./api-util');
const parseProperty = require('./parseProperty');
const parsoidSections = require('./sections/parsoidSections');
const preprocessParsoidHtml = require('./processing');
const transforms = require('./transforms');
const wikiLanguage = require('./wikiLanguage');
const MobileHTML = require('./mobile/MobileHTML');
/**
 * Generic function to get page content from the REST API.
 * @param {!Object} req the request object
 * @param {!string} endpoint the content desired, e.g., 'html', 'mobile-sections'
 * @param {!string} spec the endpoint spec to use to generate the content-type request header
 * @return {!promise} Promise for the requested content
 */
function _getRestPageContent(req, endpoint, spec) {
    const rev = req.params.revision;
    let suffix = '';
    if (rev) {
        suffix = `/${rev}`;
        const tid = req.params.tid;
        if (tid) {
            req.logger.log('warn/tid', 'tid used in Parsoid request');
            suffix += `/${tid}`;
        }
    }
    const path = `page/${endpoint}/${encodeURIComponent(req.params.title)}${suffix}`;
    const restReq = { headers: {
        accept: mUtil.getContentTypeString(spec),
        'accept-language': req.headers['accept-language']
    } };
    return api.restApiGet(req, path, restReq);
}

/**
 * @param {!Object} req the request object
 * @return {!promise} Promise for the raw Parsoid HTML of the given page/rev/tid
 */
function getParsoidHtml(req) {
    return _getRestPageContent(req, 'html', mUtil.CONTENT_TYPES.html);
}

/**
 * Retrieves the etag from the headers if present. Strips the weak etag prefix (W/) and enclosing
 * quotes.
 * @param {?Object} headers an object of header name/values
 * @return {?string} etag
 */
function getEtagFromHeaders(headers) {
    if (headers && headers.etag) {
        return headers.etag.replace(/^W\//, '').replace(/"/g, '');
    }
}

/**
 * Retrieves the revision from the etag emitted by Parsoid.
 * @param {?Object} headers an object of header name/values
 * @return {?string} revision portion of etag, if found
 */
function getRevisionFromEtag(headers) {
    const etag = getEtagFromHeaders(headers);
    if (etag) {
        return etag.split('/').shift();
    }
}

/**
 * Retrieves the revision and tid from the etag emitted by Parsoid.
 * @param {?Object} headers an object of header name/values
 * @return {?Object} revision and tid from etag, if found
 */
function getRevAndTidFromEtag(headers) {
    const etag = getEtagFromHeaders(headers);
    if (etag) {
        const etagComponents = etag.split('/');
        return {
            revision: etagComponents[0],
            tid: etagComponents[1]
        };
    }
}

/**
 * <meta property="dc:modified" content="2015-10-05T21:35:32.000Z"/>
 * @param {!Document} doc Parsoid DOM document
 * @return {?string} last modified time stamp in ISO8601 format or undefined
 */
function getModified(doc) {
    const head = doc.head;
    if (!head) {
        return undefined;
    }
    const meta = head.querySelector('meta[property="dc:modified"]');
    if (!meta) {
        return undefined;
    }
    return meta.getAttribute('content')
        .replace(/\.000Z$/, 'Z');
}

/**
 * <meta property="dc:modified" content="2015-10-05T21:35:32.000Z"/>
 * @param {!string} html Parsoid HTML string
 */
function getModifiedFromHtml(html) {
    return `${html.match(/<meta[^>]*?property="dc:modified"[^>]*?\/>/i)[0]
        .match(/content="(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}).\d{3}Z"/i)[1]}Z`;
}

/**
 * @param {!Object} app the application object
 * @param {!Object} req the request object
 * @return {!promise} Returns a promise to retrieve the page content from Parsoid
 */
function pageJsonPromise(app, req) {
    const lang = wikiLanguage.getLanguageCode(req.params.domain);
    return getParsoidHtml(req)
        .then((response) => {
            const page = getRevAndTidFromEtag(response.headers);
            return mUtil.createDocument(response.body)
            .then((doc) => {
                // Note: these properties must be obtained before stripping markup
                page.lastmodified = getModified(doc);
                page.pronunciation = parseProperty.parsePronunciation(doc);
                page.spoken = parseProperty.parseSpokenWikipedia(doc);
                page.hatnotes = transforms.extractHatnotesForMobileSections(doc, lang);
                page.issues = transforms.extractPageIssuesForMobileSections(doc);
                page._headers = {
                    'Content-Language': response.headers && response.headers['content-language'],
                    Vary: response.headers && response.headers.vary
                };
                return preprocessParsoidHtml(doc, app.conf.processing_scripts['mobile-sections'])
                .then((doc) => {
                    page.sections = parsoidSections.getSectionsText(doc, req.logger);
                    return page;
                });
            });
        });
}

/**
 * @param {!Object} app the application object
 * @param {!Object} res the response or request object
 * @return {!promise} Returns a promise to the processed content
 */
function mobileHTMLPromiseFromHTML(app, res, html) {
    const meta = getRevAndTidFromEtag(res.headers) || {};
    meta._headers = {
        'Content-Language': res.headers && res.headers['content-language'],
        Vary: res.headers && res.headers.vary
    };
    meta.baseURI = app.conf.mobile_html_rest_api_base_uri;
    return mUtil.createDocument(html)
    .then((doc) => {
        return MobileHTML.promise(doc, meta);
    });
}

/**
 * @param {!Object} app the application object
 * @param {!Object} req the request object
 * @param {?boolean} [optimized] if true will apply additional transformations
 * to reduce the payload
 * @return {!promise} Returns a promise to retrieve the page content from Parsoid
 */
function mobileHTMLPromise(app, req) {
    return getParsoidHtml(req)
        .then((res) => {
            return mobileHTMLPromiseFromHTML(app, res, res.body);
        });
}

/**
 * @param {!Object} app the application object
 * @param {!Object} req the request object
 * @return {!promise} Returns a promise to retrieve the page content from Parsoid
 */
function pageHtmlPromiseForReferences(app, req) {
    return getParsoidHtml(req)
        .then((response) => {
            const meta = getRevAndTidFromEtag(response.headers);
            meta._headers = {
                'Content-Language': response.headers && response.headers['content-language'],
                Vary: response.headers && response.headers.vary
            };
            return mUtil.createDocument(response.body)
            .then(doc => preprocessParsoidHtml(doc, app.conf.processing_scripts.references))
            .then((doc) => {
                return { meta, doc };
            });
        });
}

module.exports = {
    pageJsonPromise,
    mobileHTMLPromise,
    mobileHTMLPromiseFromHTML,
    pageHtmlPromiseForReferences,
    getParsoidHtml,
    getRevisionFromEtag,
    getRevAndTidFromEtag,
    getModified,
    getModifiedFromHtml,

    // VisibleForTesting
    getEtagFromHeaders
};
