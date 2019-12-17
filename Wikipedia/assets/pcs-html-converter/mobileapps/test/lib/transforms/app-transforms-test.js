'use strict';

const domino = require('domino');
const assert = require('../../utils/assert');
const fixVideoAnchor = require('../../../lib/transforms').fixVideoAnchor;

describe('lib:app-transforms', () => {
    it('fixVideoAnchor should skip video tags just holding audio', () => {
        const doc = domino.createDocument(`
<div><figure-inline typeof="mw:Audio"><span>
        <video
                controls=""
                preload="none">
                <source
                        src="https://upload.wikimedia.org/wikipedia/en/c/c4/Radiohead_-_Creep_%28sample%29.ogg"
                        type='audio/ogg; codecs="vorbis"'/>
        </video>
</span></figure-inline></div>`);
        fixVideoAnchor(doc);
        const videoThumbImgElements = doc.querySelectorAll('a.app_media');
        assert.equal(videoThumbImgElements.length, 0, 'Should not have marked the audio file');
    });

    it('fixVideoAnchor should transform actual videos', () => {
        const doc = domino.createDocument(`
<figure typeof="mw:Video/Thumb mw:Placeholder" id="mwBw"><span id="mwCA">
    <video resource="https://upload.wikimedia.org/wikipedia/commons/9/96/Curiosity%27s_Seven_Minutes_of_Terror.ogv">
        <source src="https://upload.wikimedia.org/wikipedia/commons/9/96/Curiosity%27s_Seven_Minutes_of_Terror.ogv"
        type='video/ogg; codecs="theora, vorbis"' />
    </video>
</span></figure>`);
        fixVideoAnchor(doc);
        const videoThumbImgElements = doc.querySelectorAll('a.app_media');
        assert.equal(videoThumbImgElements.length, 1, 'Should have marked the video file');
    });
});
