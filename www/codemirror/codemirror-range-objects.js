
class MarkupItem {
  constructor(type, inner, outer) {
    this.type = type
    this.inner = inner
    this.outer = outer
    this.buttonName = MarkupItem.buttonNameForType(type)
  }
  isComplete() {
    return this.inner.isComplete() && this.outer.isComplete()
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
  constructor(start, end) {
    this.start = start
    this.end = end
  }
  isComplete() {
    return this.start !== -1 && this.end !== -1
  }
}

exports.ItemRange = ItemRange
exports.MarkupItem = MarkupItem
