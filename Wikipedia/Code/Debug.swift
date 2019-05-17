import Foundation








/*

extension NSAttributedString {
    
    public func trimWhiteSpace() -> NSAttributedString {
        let invertedSet = CharacterSet.whitespacesAndNewlines.inverted
        let startRange = string.utf16.description.rangeOfCharacter(from: invertedSet)
        let endRange = string.utf16.description.rangeOfCharacter(from: invertedSet, options: .backwards)
        guard let startLocation = startRange?.upperBound, let endLocation = endRange?.lowerBound else {
            return NSAttributedString(string: string)
        }
        
        let location = string.utf16.distance(from: string.startIndex, to: startLocation) - 1
        let length = string.utf16.distance(from: startLocation, to: endLocation) + 2
        let range = NSRange(location: location, length: length)
        return attributedSubstring(from: range)
    }
    
}

extension String {
    func htmlToAttributedString() -> NSAttributedString? {
        if let htmlStringData = self.data(using: .unicode), let attributedString = try? NSMutableAttributedString     (data: htmlStringData, options: [.documentType : NSAttributedString.DocumentType.html],      documentAttributes: nil), let font = UIFont(name: "AvenirNext-Medium", size: 12) {
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 0.5 * font.lineHeight
            
            attributedString.addAttributes([
                NSAttributedString.Key.underlineColor : UIColor.clear,
                NSAttributedString.Key.underlineStyle : NSNumber(value: false),
                NSAttributedString.Key.paragraphStyle : paragraphStyle,
                NSAttributedString.Key.font : font,
                NSAttributedString.Key.foregroundColor : UIColor.blue
                ], range: NSRange(location: 0, length: attributedString.length))
            return attributedString//.trimWhiteSpace()
        }
        return nil
    }
}

*/























/*
https://stackoverflow.com/a/32660790
font-family: -apple-system-body
font-family: -apple-system-headline
font-family: -apple-system-subheadline
font-family: -apple-system-caption1
font-family: -apple-system-caption2
font-family: -apple-system-footnote
font-family: -apple-system-short-body
font-family: -apple-system-short-headline
font-family: -apple-system-short-subheadline
font-family: -apple-system-short-caption1
font-family: -apple-system-short-footnote
font-family: -apple-system-tall-body
*/
// color: #\(textColor.wmf_hexString) !important;

/*
extension String {
    func htmlAttributed(textSize: CGFloat) -> NSAttributedString? {
        do {
            let htmlWithCSS = """
            <html>
                <head>
                    <style>
                        * {
                            font-size: \(textSize)pt !important;
                            font-family: -apple-system !important;
                        }
                    </style>
                </head>
            <body>\(self)</body>
            </html>
            """
            
            guard let htmlWithCSSAsData = htmlWithCSS.data(using: String.Encoding.utf8) else {
                return nil
            }
            
            return try NSAttributedString(data: htmlWithCSSAsData, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            print("error: ", error)
            return nil
        }
    }
}

*/











class TestTextView: UITextView {
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)


//class TestTextView: UILabel {
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        numberOfLines = 0
        
/*
        attributedText = """
          Text <i>italic</i> <b>bold</b>.
          Newline.
            <hr>
          Text <i>italic</i> <b>bold</b>.
          Newline.
        """.byAttributingHTML(with: .caption2, matching: traitCollection)
*/
        
    
    
    
        let at = """

          <a href="http://cnn.com">hi there</a>
          <br><br>
          Text <i>italic</i> <b>bold</b>.
          <br><br>
          Newline.
          <ul>
              <li>Unordered list <i>item</i> one 🥶
              <li>Unordered list <b>item</b> two 🥶
          </ul>


          HELLO


          <ul>
              <li>Unordered list item one 👀
              <li>Unordered list item two 👀
          </ul>
          <ol>
              <li>Ordered list item one 🦊
              <li>Ordered list item two 🦊
          </ol>
          <ul>
              <li>Unordered list item one 🐸
              <li>Unordered list item two 🐸
              <li>Nested 🐸
                  <ol>
                      <li>Nested ordered list item one 🐵
                      <li>Nested ordered list item two 🐵
                  </ol>
          </ul>
          <ol>
              <li>Ordered list item one 🍓
              <li>Nested 🍓
                  <ul>
                      <li>Nested <i>unordered <b>list</b> item</i> one 🎲
                      <li>Nested unordered list item two 🎲
                  </ul>
              <li>Ordered list item three 🍓
          </ol>
          HELLO 2
          <ul>
            <li>Unordered list <i>item</i> one 🥶
            <li>Unordered list <b>item</b> two 🥶
          </ul>

          HELLO 3

          <ol>      <li>Ordered list item one 👻      <li>Nested 👻          <ul>              <li>Nested <i>unordered <b>list</b> item</i> one 🐥              <li>Nested unordered list item two 🐥          </ul>      <li>Ordered list item three 👻  </ol>
          <ol><li>Ordered list item one 🧁<li>Nested 🧁<ul><li>Nested <i>unordered <b>list</b> item</i> one ☘️<li>Nested unordered list item two ☘️</ul><li>Ordered list item three 🧁</ol>
        """
        .byAttributingHTML(with: .caption2, matching: traitCollection)
//        .replacingOccurrences(of: "<ul>", with: "<hr><ul>")
//        .replacingOccurrences(of: "</ul>", with: "</ul><hr>")
//        .replacingOccurrences(of: "<ol>", with: "<hr><ol>")
//        .replacingOccurrences(of: "</ol>", with: "</ol><hr>")
//        .htmlAttributed(textSize: 8)

        
        
        attributedText = at
        
//      .htmlToAttributedString()

//        backgroundColor = .black
//        textColor = .white
//

            //.byAttributingHTML(with: .caption2, matching: traitCollection)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
