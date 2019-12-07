import Foundation


let count = CommandLine.arguments.count
guard count > 1 else {
    abort()
}

struct LanguageJSON: Codable {
    let code: String
    let normalized_code: String?
    let canonical_name: String
    let name: String
}

let path = CommandLine.arguments[1]
let pathComponents = path.components(separatedBy: "/")
let languagesJSONPathComponents = pathComponents + ["Wikipedia", "assets", "languages.json"]
let languagesJSONPath = languagesJSONPathComponents.joined(separator: "/")
let languagesJSONData = try! Data(contentsOf: URL(fileURLWithPath: languagesJSONPath))
let languages = try! JSONDecoder().decode([LanguageJSON].self, from: languagesJSONData)
let jsonExtractionRegex = try! NSRegularExpression(pattern: #"(?:mw\.config\.set\()(.*?)(?:\);\n*\}\);)"#, options: [.dotMatchesLineSeparators])

func extractJSONString(from responseString: String) -> String? {
    let results = jsonExtractionRegex.matches(in: responseString, range: NSRange(responseString.startIndex..., in: responseString))
    guard
        results.count == 1,
        let firstResult = results.first,
        firstResult.numberOfRanges == 2,
        let soughtCaptureGroupRange = Range(firstResult.range(at: 1), in: responseString)
    else {
        return nil
    }
    return String(responseString[soughtCaptureGroupRange])
}


func validate(json: String, completion: @escaping (Bool) -> Void) {
    var urlComponents = URLComponents()
    urlComponents.scheme = "http"
    urlComponents.host = "localhost"
    urlComponents.port = 3000
    urlComponents.queryItems = [
       URLQueryItem(name: "jsonToValidate", value: json)
    ]
    guard let url = urlComponents.url else {
        completion(false)
        return
    }
    URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else {
            completion(false)
            return
        }
        guard let responseString = String(data: data, encoding: .utf8) else {
            completion(false)
            return
        }
        guard responseString == "true" else {
            completion(false)
            return
        }
        completion(true)
    }.resume()
}


func getCodeMirrorConfigJSON(for wikiLanguage: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "http://\(wikiLanguage).wikipedia.org/w/load.php?debug=false&lang=en&modules=ext.CodeMirror.data") else {
        completion(nil)
        return
    }
    URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else {
            completion(nil)
            return
        }
        guard let responseString = String(data: data, encoding: .utf8) else {
            completion(nil)
            return
        }
        guard let soughtSubstring = extractJSONString(from: responseString) else {
            completion(nil)
            return
        }
        
        let cleanedString = soughtSubstring.replacingOccurrences(of: "!0", with: "true")
        
        
//        let jsonData = cleanedString.data(using: String.Encoding.utf8)
//        if JSONSerialization.isValidJSONObject(jsonData) {
//            print("Valid Json")
//        } else {
//            print("InValid Json")
//        }
        
        validate(json: cleanedString) { isValid in
            if isValid {
                completion(cleanedString)
            } else {
                completion(nil)
            }
        }
        
//        completion(cleanedString)
    }.resume()
}

let group = DispatchGroup()
for language in languages {
    let codes = [language.normalized_code, language.code].compactMap({ $0 })
    for code in codes {
        group.enter()
        getCodeMirrorConfigJSON(for: code) { (response) in
            defer {
                group.leave()
            }
            guard let response = response else {
                return
            }
            let outputComponents = pathComponents + ["Wikipedia", "assets", "codemirror", "config", "codemirror-config-\(language.code).json"]
            let outputPath = outputComponents.joined(separator: "/")
            
            // print("\n\n\n\(response)\n\n\n")
            
            try! response.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
        }
    }
}


group.notify(queue: DispatchQueue.main) {
    exit(0)
}

dispatchMain()
