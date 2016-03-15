//
//  WFEvent.swift
//  WFEventHubClient
//
//  Created by Whitney Foster on 3/10/16.
//  Copyright © 2016 WhitneyFoster. All rights reserved.
//

import Foundation
import SwiftyJSON

//extension String {
//    func toBytes() -> [UInt32]? {
//        return self.dataUsingEncoding(NSUTF8StringEncoding)?.toBytes()
//    }
//}
//
//extension NSData {
//    func toBytes() -> [UInt32]? {
//        var array: [UInt32]?
//        // the number of elements:
//        let count = self.length / sizeof(UInt32)
//        
//        // create array of appropriate length:
//        array = [UInt32](count: count, repeatedValue: 0)
//        
//        // copy bytes into array
//        self.getBytes(&array, length:count * sizeof(UInt32))
//        
//        print(array!)
//        // Output: [32, 4, 123, 4, 5, 2]
//        return array
//    }
//}

// MARK: - WFEvent
class WFEvent {
    let parameters: [String: AnyObject]
    
    init(parameters p: [String: AnyObject]) {
        self.parameters = p
    }
    
    func getData() -> NSData? {
        var params = [Dictionary<String, AnyObject>]()
        for o in self.parameters {
            params.append([o.0: o.1])
        }
        var data: NSData?
        do {
            data = try JSON(params).rawData()
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        return data
    }
    
    func contentLength() -> Int {
        return self.getData()?.length ?? 0
    }
}


// MARK: - WFError
class WFError: ErrorType {
    private let errCode: Int
    private let message: String
    
    init(code: Int, message: String) {
        self.errCode = code
        self.message = message
    }
}

// MARK: - WFEventHubAuthorization
struct WFEventHubAuthorization {
    private let server: String // should be encoded
    private let keyName: String
    private let key: String
    let nameSpace: String
    
    init(nameSpace s: String, keyName n: String, key k: String) {
        self.nameSpace = s
        self.server = "https://\(self.nameSpace).servicebus.windows.net/"
        self.keyName = n
        self.key = k
    }
    
    func getAuthString() -> String {
        let expiry = NSDate().timeIntervalSince1970 + 604800 //unix timestamp + seconds in one week
        let signatureToSign = "\(self.server)\\n\(expiry)"
        let hmac = signatureToSign.hmac(CryptoAlgorithm.SHA256, key: key)
        let sasToken = "SharedAccessSignature sr=\(self.server)&sig=\(hmac)&se=\(expiry)&skn=\(self.keyName)"
        print(sasToken)
        return sasToken
    }
}

// MARK: - WFEventHubClient
class WFEventHubClient {
    static let sharedClient: WFEventHubClient = WFEventHubClient()
    private var events: [WFEvent] = [WFEvent]()
    private var timer: NSTimer?
    private var eventHub: String?
    private var authorization: WFEventHubAuthorization?
    private var urlRequest: NSMutableURLRequest?
    
    private init() {
        
    }
    
    func setAuthorization(authorization: WFEventHubAuthorization, eventHub h: String, contentType: String, host: String) {
        self.authorization = authorization
        self.eventHub = h
        let requestString = "https://\(self.authorization!.nameSpace).servicebus.windows.net/\(self.eventHub)/messages"
        let url = NSURL(string: requestString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet())!)
        self.urlRequest = NSMutableURLRequest(URL: url!)
        self.urlRequest?.HTTPMethod = "POST";
        self.urlRequest?.setValue(self.authorization?.getAuthString() ?? "", forHTTPHeaderField: "Authorization")
        self.urlRequest?.setValue(contentType, forHTTPHeaderField: "Content-Type")
        self.urlRequest?.setValue(host, forHTTPHeaderField: "Host")
    }
    
    func queueEvent(event: WFEvent) {
        var futureSize = event.contentLength()
        for e in self.events {
            futureSize += e.contentLength()
        }
        if futureSize >= 256 {
            self.sendAllEvents()
        }
        self.events.append(event)
        if self.timer == nil {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(300, target: self, selector: "sendAllEvents", userInfo: nil, repeats: false)
        }
    }
    
    func sendAllEvents() {
        self.timer = nil
        var length = 0
        var events: String = ""
        var i = 1
        for e in self.events {
            length += e.contentLength()
            events += "{"
            var j = 1
            for p in e.parameters {
                events += "\(p.0):\(p.1)" + ((j == e.parameters.count) ? "" : ",")
                j++
            }
            events += (i == self.events.count) ? "}" : "}, "
            i++
        }
        print(events)
        
        self.urlRequest?.setValue("\(length)", forHTTPHeaderField: "Content-Length")
        self.urlRequest?.setValue("100-continue", forHTTPHeaderField: "Expect")
        
        self.urlRequest?.HTTPBody = events.dataUsingEncoding(NSUTF8StringEncoding)
        NSURLConnection.sendAsynchronousRequest(self.urlRequest!, queue: NSOperationQueue.currentQueue() ?? NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
            print(response)
            print(data)
            print(error)
        }
        
    }
    
    
}