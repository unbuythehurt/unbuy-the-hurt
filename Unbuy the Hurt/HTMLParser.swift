//
//  HTMLParser.swift
//  Unbuy the Hurt
//
//  Created by Mike Kavouras on 10/27/14.
//  Copyright (c) 2014 Mike Kavouras. All rights reserved.
//

import UIKit

protocol HTMLParserDelegate {
    func didFinishParsingHTML(data: Dictionary<String, AnyObject>)
}

class HTMLParser: NSObject {

    typealias JSON = AnyObject
    typealias JSONDictionary = Dictionary<String, JSON>
    typealias JSONArray = Array<JSONDictionary>
    
    var delegate : HTMLParserDelegate?
    
    let companyQueryString: String = "//div[@class='entry-content']/h2"
    
    let brandQueryString: String = "//div[@class='entry-content']/ul/li"
    
    let CacheFileName : String = "cache.json"
    
    lazy var parser : TFHpple = {
        let HTMLURL: NSURL? = NSURL(string: "http://veganrabbit.com/list-of-companies-that-do-test-on-animals/")
        if let url = HTMLURL {
            let HTMLData : NSData? = NSData(contentsOfURL: url)
            if let data = HTMLData {
                return TFHpple(HTMLData: data)
            }
        }
        return TFHpple()
    }()
    
    func parseHTML() {
        if let cache : Dictionary<String, AnyObject> = cachedResuts() as? Dictionary<String,AnyObject> {
            if let cacheDate: NSDate = cache["date"] as? NSDate {
                if NSDate().timeIntervalSinceDate(cacheDate) > 60 * 60 * 24 {
                    fetchAndCacheHTML()
                } else {
                    self.delegate?.didFinishParsingHTML(cache)
                }
            }
        } else {
            fetchAndCacheHTML()
        }
    }
    
    private func fetchAndCacheHTML() {
        let data = self.fetchAndParseHTML()
        self.cacheResults(data)
        self.delegate?.didFinishParsingHTML(data)
    }
    
    private func fetchAndParseHTML() -> Dictionary<String, AnyObject> {
        let companies : [String] = self.parseHeaders()
        let brands : [String] = self.parseBrands()
        let data : [String:AnyObject] = ["date" : NSDate(), "companies" : companies, "brands" : brands]
        
        return data
    }

    private func parseHeaders() -> [String] {
        var headers : [String] = []
        let queryString = companyQueryString
        let headerNodesArray : NSArray = parser.searchWithXPathQuery(queryString) as NSArray
        for nodeJSON in headerNodesArray {
            let node : TFHppleElement = nodeJSON as TFHppleElement
            let children : NSArray = node.children as NSArray
            if let firstChild : TFHppleElement = children.firstObject as? TFHppleElement {
                let attributes = firstChild.attributes
                if !attributes.isEmpty {
                    let headerNode : NSArray = firstChild.children as NSArray
                    if let header : TFHppleElement = headerNode.firstObject as? TFHppleElement {
                        if header.content != nil {
                            let str = header.content.sterilize()
                            if !str.isEmpty {
                                headers.append(str)
                            }
                        }
                    }
                }
            }
        }
        return headers
    }
    
    private func parseBrands() -> [String] {
        var brands : [String] = []
        let queryString = brandQueryString
        let listNodesArray : NSArray = parser.searchWithXPathQuery(queryString) as NSArray
        for nodeJSON in listNodesArray {
            let node : TFHppleElement = nodeJSON as TFHppleElement
            let children : NSArray = node.children as NSArray
            if let firstChild : TFHppleElement = children.firstObject as? TFHppleElement {
                let attributes = firstChild.attributes
                if attributes.isEmpty {
                    if firstChild.content != nil {
                        let str = firstChild.content.sterilize()
                        if !str.isEmpty {
                            brands.append(str)
                        }
                    }
                }
            }
        }
        return brands
    }
    
    private func cacheResults(data: Dictionary<String, AnyObject>) {
        (data as NSDictionary).writeToFile(filePath(), atomically: true)
    }
    
    private func cachedResuts() -> NSDictionary? {
        let results = NSDictionary(contentsOfFile: filePath())
        return results
    }
    
    private func filePath() -> String {
        let documentsPath : NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let destinationPath = documentsPath.stringByAppendingPathComponent(CacheFileName)
        return destinationPath
    }
}
