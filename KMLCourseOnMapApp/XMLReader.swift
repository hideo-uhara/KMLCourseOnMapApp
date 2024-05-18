//
// XMLReader.swift
//

import Foundation

class XMLReader: XMLParser {
	static let textNodeKey: String = "t-node" // textノードを保持するキー名
	
	var stack: [[String: Any]] = [[:]]
	
	init(url: URL) {
		var data: Data = Data()
		
		do {
			data = try Data(contentsOf: url)
		} catch {
			NSLog(error.localizedDescription)
		}
		
		super.init(data: data)
	}
	
	func load() throws -> [String: Any] {
		self.delegate = self
		
		if !super.parse() {
			NSLog("Error:XMLReader:load")
			
			if let error = super.parserError {
				NSLog("%@", error.localizedDescription)
			}
			
			throw NSError(domain: NSCocoaErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not load."])
		}
		
		return self.stack.first!
	}
}

extension XMLReader: XMLParserDelegate {
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		let dict: [String: Any] = [XMLReader.textNodeKey: ""]
		
		/*
		var dict: [String: Any] = [XMLReader.textNodeKey: ""]
		
		for key: String in attributeDict.keys {
			dict.updateValue(attributeDict[key]!, forKey: key)
		}
		*/
		
		self.stack.append(dict)
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		let dict: [String: Any] = self.stack.last!
		
		self.stack.removeLast()
		
		if self.stack[self.stack.count - 1][elementName] != nil {
			// <item>a</item><item>b</item>のような場合
			if var array: [Any] = self.stack[self.stack.count - 1][elementName] as? [Any] {
				array.append(dict) // 配列の最後に追加
				self.stack[self.stack.count - 1][elementName] = array // 置き換え
			} else {
				self.stack[self.stack.count - 1][elementName] = [self.stack[self.stack.count - 1][elementName], dict] // 配列に置き換え
			}
		} else {
			self.stack[self.stack.count - 1][elementName] = dict
		}
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String) {
		let dict: [String: Any] = self.stack.last!
		let text: String = dict[XMLReader.textNodeKey] as! String
		
		self.stack[self.stack.count - 1][XMLReader.textNodeKey] = text + string // 置き換え
	}

}
