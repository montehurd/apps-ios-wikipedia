
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
  
  endsInsideRange(range) {
    return (
      this.endLocation.greaterThanOrEquals(range.startLocation)
      &&
      this.endLocation.lessThanOrEquals(range.endLocation)
    )
  }
  
  startsInsideRange(range) {
    return (
      this.startLocation.greaterThanOrEquals(range.startLocation)
      &&
      this.startLocation.lessThanOrEquals(range.endLocation)
    )
  }

  intersectsRange(range) {
    return (
      this.endsInsideRange(range)
      ||
      this.startsInsideRange(range)
      ||
      range.endsInsideRange(this)
      ||
      range.startsInsideRange(this)
    )
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
  greaterThan(location) {
    if (this.line < location.line) {
      return false
    }
    if (this.line === location.line && this.ch <= location.ch) {
      return false
    }
    return true
  }
  lessThan(location) {
    if (this.line > location.line) {
      return false
    }
    if (this.line === location.line && this.ch >= location.ch) {
      return false
    }
    return true
  }
  equals(location) {
    return (this.line === location.line && this.ch === location.ch)
  }
  greaterThanOrEquals(location) {
    return this.greaterThan(location) || this.equals(location)
  }
  lessThanOrEquals(location) {
    return this.lessThan(location) || this.equals(location)
  }
}

exports.ItemRange = ItemRange
exports.MarkupItem = MarkupItem
exports.ItemLocation = ItemLocation
