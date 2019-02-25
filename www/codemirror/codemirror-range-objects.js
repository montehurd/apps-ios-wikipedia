
class MarkupItem {
  constructor(type, innerRange, outerRange) {
    this.type = type
    this.innerRange = innerRange
    this.outerRange = outerRange
    this.buttonName = MarkupItem.buttonNameForType(type)
  }
  isComplete() {
    return this.innerRange.isComplete() && this.outerRange.isComplete()
  }
  static buttonNameForType(type) {
    if (type === 'mw-apostrophes-bold') {
      return 'bold'
    }
    if (type === 'mw-section-header') {
      return 'header'
    }
    if (type === 'mw-link-bracket') {
      return 'link'
    }
    if (type === 'mw-template-bracket') {
      return 'template'
    }
    if (type === 'mw-apostrophes-italic') {
      return 'italic'
    }
    return type  
  }
}

class ItemRange {
  constructor(startLocation, endLocation) {
    this.startLocation = startLocation
    this.endLocation = endLocation
  }
  isComplete() {
    return this.startLocation.isComplete() && this.endLocation.isComplete()
  }
}

class ItemLocation {
  constructor(line, ch) {
    this.line = line
    this.ch = ch
  }
  isComplete() {
    return this.line !== -1 && this.ch !== -1
  }
}

exports.ItemRange = ItemRange
exports.MarkupItem = MarkupItem
exports.ItemLocation = ItemLocation
