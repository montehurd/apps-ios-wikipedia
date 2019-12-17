import AdjustTextSize from '../../transform/AdjustTextSize'
import BodySpacingTransform from '../../transform/BodySpacingTransform'
import CollapseTable from '../../transform/CollapseTable'
import DimImagesTransform from '../../transform/DimImagesTransform'
import EditTransform from '../../transform/EditTransform'
import InteractionHandling from './InteractionHandling'
import L10N from './L10N'
import LazyLoadTransformer from '../../transform/LazyLoadTransformer'
import PlatformTransform from '../../transform/PlatformTransform'
import Scroller from './Scroller'
import ThemeTransform from '../../transform/ThemeTransform'

const unitsRegex = /[^0-9]+$/

/**
 * @typedef {function} OnSuccess
 * @return {void}
 */

/**
 * Makes multiple page modifications based on client specific settings, which should be called
 * during initial page load.
 * @param {?{}} optionalSettings client settings
 *   { platform, clientVersion, l10n, theme, dimImages, margins, areTablesInitiallyExpanded,
 *   scrollTop, textSizeAdjustmentPercentage }
 * @param {?Page~Function} onSuccess callback
 * @return {void}
 */
const setup = (optionalSettings, onSuccess) => {
  const settings = optionalSettings || {}
  if (settings.platform !== undefined) {
    PlatformTransform.setPlatform(document, PlatformTransform.CLASS_PREFIX + settings.platform)
  }
  if (settings.l10n !== undefined) {
    L10N.localizeLabels(settings.l10n)
  }
  if (settings.theme !== undefined) {
    ThemeTransform.setTheme(document, ThemeTransform.CLASS_PREFIX + settings.theme)
  }
  if (settings.dimImages !== undefined) {
    DimImagesTransform.dimImages(document, settings.dimImages)
  }
  let metaTags // lazy load these to avoid a double query selector
  if (settings.margins !== undefined || settings.leadImageHeight !== undefined) {
    const margins = settings.margins || {}
    if (settings.leadImageHeight !== undefined) {
      if (!metaTags) {
        metaTags = getMetaTags()
      }
      const leadImage = getLeadImageFromMetaTags(metaTags)
      if (leadImage.source) {
        if (margins.top) {
          const top = parseFloat(margins.top, 10)
          const height = parseFloat(settings.leadImageHeight, 10)
          const units = margins.top.match(unitsRegex) || ""
          margins.top =  top + height + units
        } else {
          margins.top = settings.leadImageHeight
        }
      }
    }
    BodySpacingTransform.setMargins(document.body, margins)
  }
  if (settings.userGroups !== undefined) {
    if (!metaTags) {
      metaTags = getMetaTags()
    }
    const protection = getProtectionFromMetaTags(metaTags)
    let isEditable = true
    let isProtected = false
    if (protection.edit) {
      isProtected = true
      for (let i = 0; i < settings.userGroups.length; i++) {
        let userGroup = settings.userGroups[i]
        if (userGroup === protection.edit) {
          isProtected = false
          break
        }
      }
    }
    setEditButtons(isEditable, isProtected)
  }
  if (settings.setupTableEventHandling === undefined || settings.setupTableEventHandling) {
    const isInitiallyCollapsed = settings.areTablesInitiallyExpanded !== true
    CollapseTable.setupEventHandling(window,
      document,
      isInitiallyCollapsed,
      Scroller.scrollWithDecorOffset)
  }
  if (settings.scrollTop !== undefined) {
    Scroller.setScrollTop(settings.scrollTop)
  }
  if (settings.textSizeAdjustmentPercentage !== undefined) {
    AdjustTextSize.setPercentage(
      document.body,
      settings.textSizeAdjustmentPercentage
    )
  }
  if (settings.loadImages === undefined || settings.loadImages === true) {
    const lazyLoader = new LazyLoadTransformer(window, 2)
    lazyLoader.collectExistingPlaceholders(document.body)
    lazyLoader.loadPlaceholders()
  }
  if (onSuccess instanceof Function) {
    if (window && window.requestAnimationFrame) {
      // request animation frame and set timeout before callback to ensure paint occurs
      window.requestAnimationFrame(() => {
        setTimeout(() => {
          onSuccess()
        }, 1)
      })
    } else {
      onSuccess()
    }
  }
}

/**
 * Sets the theme.
 * @param {!string} theme one of the values in Themes
 * @param {?OnSuccess} onSuccess callback
 * @return {void}
 */
const setTheme = (theme, onSuccess) => {
  ThemeTransform.setTheme(document, theme)

  if (onSuccess instanceof Function) {
    onSuccess()
  }
}

/**
 * Toggles dimming of images.
 * @param {!boolean} dimImages true if images should be dimmed, false otherwise
 * @param {?OnSuccess} onSuccess callback
 * @return {void}
 */
const setDimImages = (dimImages, onSuccess) => {
  DimImagesTransform.dimImages(document, dimImages)

  if (onSuccess instanceof Function) {
    onSuccess()
  }
}

/**
 * Sets the margins.
 * @param {!{BodySpacingTransform.Spacing}} margins
 * @param {?OnSuccess} onSuccess callback
 * @return {void}
 */
const setMargins = (margins, onSuccess) => {
  BodySpacingTransform.setMargins(document.body, margins)

  if (onSuccess instanceof Function) {
    onSuccess()
  }
}

/**
 * Sets the top scroll position for collapsing of tables (when bottom close button is tapped).
 * @param {!number} scrollTop height of decor covering the top portion of the Viewport in pixel
 * @param {?OnSuccess} onSuccess callback
 * @return {void}
 */
const setScrollTop = (scrollTop, onSuccess) => {
  Scroller.setScrollTop(scrollTop)

  if (onSuccess instanceof Function) {
    onSuccess()
  }
}

/**
 * Sets text size adjustment percentage of the body element
 * @param  {!string} textSize percentage for text-size-adjust in format of string, like '100%'
 * @param  {?OnSuccess} onSuccess onSuccess callback
 * @return {void}
 */
const setTextSizeAdjustmentPercentage = (textSize, onSuccess) => {
  AdjustTextSize.setPercentage(document.body, textSize)

  if (onSuccess instanceof Function) {
    onSuccess()
  }
}

/**
 * Enables edit buttons to be shown (and which ones).
 * @param {?boolean} isEditable true if edit buttons should be shown
 * @param {?boolean} isProtected true if the protected edit buttons should be shown
 * @param {?OnSuccess} onSuccess onSuccess callback
 * @return {void}
 */
const setEditButtons = (isEditable, isProtected, onSuccess) => {
  EditTransform.setEditButtons(document, isEditable, isProtected)

  if (onSuccess instanceof Function) {
    onSuccess()
  }
}

/**
 * Gets the revision of the current mobile-html page.
 * @return {string}
 */
const getRevision = () => {
  const about = document.documentElement.getAttribute('about')
  return about.substring(about.lastIndexOf('/') + 1)
}

/**
 * Get structured table of contents data
 * @return {!Array}
 */
const getTableOfContents = () => {
  const sections = document.querySelectorAll('section')
  const result = []
  const levelCounts = new Array(10).fill(0)
  let lastLevel = 0;

  [].forEach.call(sections, section => {
    const id = parseInt(section.getAttribute('data-mw-section-id'), 10)
    if (!id || isNaN(id) || id < 1) {
      return
    }
    const headerEl = section.querySelector('h1,h2,h3,h4,h5,h6')
    if (!headerEl) {
      return
    }
    const level = parseInt(headerEl.tagName.charAt(1), 10) - 1
    if (level < lastLevel) {
      levelCounts.fill(0, level)
    }
    lastLevel = level
    levelCounts[level - 1]++
    result.push({
      level,
      id,
      number: levelCounts.slice(0, level).map(n => n.toString()).join('.'),
      anchor: headerEl.getAttribute('id'),
      title: headerEl.innerHTML.trim()
    })
  })
  return result
}

/**
 * Get protection information for the page from given meta tags
 * @private
 * @param {!array} metaTags
 * @return {!map}
 */
const getProtectionFromMetaTags = (metaTags) => {
  const protection = {}
  const protectionPrefix = 'mw:pageProtection:'
  const protectionPrefixLength = protectionPrefix.length
  metaTags.forEach(metaTag => {
    const property = metaTag.getAttribute('property')
    if (property && property.startsWith(protectionPrefix)) {
      protection[property.substring(protectionPrefixLength)] = metaTag.getAttribute('content')
    }
  })
  return protection
}

/**
 * Return meta tags for the page
 * @private
 * @return {!array}
 */
const getMetaTags = () => {
  return document.head.querySelectorAll('meta')
}

/**
 * Get protection information for the page
 * @return {!map}
 */
const getProtection = () => {
  return getProtectionFromMetaTags(getMetaTags())
}


/**
 * Gets the lead image for a page
 * @private
 * @param {!array} metaTags
 * @return {!map}
 */
const getLeadImageFromMetaTags = (metaTags) => {
  const image = {}
  const leadImageProperty = 'mw:leadImage'
  for (let i = 0; i < metaTags.length; i++) {
    let metaTag = metaTags[i]
    const property = metaTag.getAttribute('property')
    if (!property || property !== leadImageProperty) {
      continue
    }
    image.source =  metaTag.getAttribute('content')
    const widthString = metaTag.getAttribute('data-file-width')
    if (widthString) {
      image.width = parseInt(widthString, 10)
    }
    const heightString = metaTag.getAttribute('data-file-height')
    if (heightString) {
      image.height = parseInt(heightString, 10)
    }
    break
  }
  return image
}

/**
 * Gets the lead image for a page
 * @return {!map}
 */
const getLeadImage = () => {
  return getLeadImageFromMetaTags(getMetaTags())
}

/**
 * Gets the Scroller object. Just for testing!
 * @return {{setScrollTop, scrollWithDecorOffset}}
 */
const getScroller = () => Scroller

/**
 * Executes pagelib functionality intended to run before any content has loaded
 * @return {void}
 */
const onBodyStart = () => {
  if (!document) {
    return
  }

  // eslint-disable-next-line no-undef
  if (typeof pcsClient !== 'undefined' && pcsClient.getSetupSettings) {
    // eslint-disable-next-line no-undef
    const setupJSON = pcsClient.getSetupSettings()
    document.pcsSetupSettings = JSON.parse(setupJSON)
  }

  // eslint-disable-next-line no-undef
  if (typeof pcsClient !== 'undefined' && pcsClient.onReceiveMessage) {
    document.pcsActionHandler = action => {
      // eslint-disable-next-line no-undef
      pcsClient.onReceiveMessage(JSON.stringify(action))
    }
  }

  if (document.pcsActionHandler) {
    InteractionHandling.setInteractionHandler(document.pcsActionHandler)
  }
  // eslint-disable-next-line require-jsdoc
  const initialSetupCompletion = () => {
    InteractionHandling.initialSetupComplete()
  }
  if (document.pcsSetupSettings) {
    const preSettings = {
      margins: document.pcsSetupSettings.margins,
      leadImageHeight: document.pcsSetupSettings.leadImageHeight,
      userGroups: document.pcsSetupSettings.userGroups,
      theme: document.pcsSetupSettings.theme,
      platform: document.pcsSetupSettings.platform,
      loadImages: false,
      setupTableEventHandling: false
    }
    setup(preSettings, initialSetupCompletion)
    return
  }

  const defaultInitialSettings = {
    loadImages: false,
    setupTableEventHandling: false
  }

  const href = document.location && document.location.href
  if (href) {
    const match = href.match(/[?&]theme=([a-z]+)(?:&|$)/)
    if (match && match.length > 1) {
      defaultInitialSettings.theme = match[1]
    }
  }

  setup(defaultInitialSettings, initialSetupCompletion)
}

/**
 * Executes pagelib functionality intended to run after all content has loaded
 * @return {void}
 */
const onBodyEnd = () => {
  if (!document) {
    return
  }
  let remainingContentTimeout = 100

  /**
   * Executed when final setup is complete
   * @return {void}
   */
  const finalSetupComplete = () => {
    InteractionHandling.finalSetupComplete()
  }
  if (document.pcsSetupSettings) {
    const postSettings = document.pcsSetupSettings
    delete postSettings.theme
    delete postSettings.margins
    delete postSettings.userGroups
    delete postSettings.leadImageHeight
    delete postSettings.platform
    postSettings.setupTableEventHandling = true
    setup(postSettings, finalSetupComplete)
    remainingContentTimeout = document.pcsSetupSettings.remainingTimeout || remainingContentTimeout
  } else {
    setup({ setupTableEventHandling: true, areTablesInitiallyExpanded: true }, finalSetupComplete)
  }

  setTimeout(() => {
    const sections = document.querySelectorAll('section')
    for (let i = 1; i < sections.length; i++) {
      sections[i].style.display = ''
    }
  }, remainingContentTimeout)
}

export default {
  onBodyStart,
  onBodyEnd,
  setup,
  setTheme,
  setDimImages,
  setMargins,
  setScrollTop,
  setTextSizeAdjustmentPercentage,
  setEditButtons,
  getLeadImage,
  getProtection,
  getRevision,
  getTableOfContents,
  testing: {
    getScroller
  }
}