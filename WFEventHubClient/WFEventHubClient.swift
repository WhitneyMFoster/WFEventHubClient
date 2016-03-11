//
//  WFEvent.swift
//  WFEventHubClient
//
//  Created by Whitney Foster on 3/10/16.
//  Copyright © 2016 WhitneyFoster. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// MARK: - WFEvent
class WFEvent {
    private(set) var contentLength: Int = 0
    private(set) var body: JSON? = nil
    
    init(var parameters: [String: AnyObject]) {
        var b = "{"
        var count = 0
        for o in parameters {
            count++
            b += "\(o.0):\(o.1)"
            if count < parameters.count {
                b += ","
            }
        }
        b += "}"
        b = b.stringByReplacingOccurrencesOfString(" ", withString: "")
        self.body = JSON.parse(b)
        self.contentLength = b.characters.count
    }
}


// MARK: - WFError
class WFError: ErrorType {
    private let errCode: Int
    private let message: String
    
    /**
     Error type
     */
    init(code: Int, message: String) {
        self.errCode = code
        self.message = message
    }
}

// MARK: - WFEventHubAuthorization
struct WFEventHubAuthorization {
    private var url: String = ""
    private var consumerGroup: String = ""
    private var policyName: String = ""
    private var policyPrimaryKey: String = ""
    private var policySecondaryKey: String = ""
    
    init () {
        
    }
    
    init(url: String, consumerGroup: String, policyName: String, policyPrimaryKey: String, policySecondaryKey: String) {
        self.url = url
        self.consumerGroup = consumerGroup
        self.policyName = policyName
        self.policyPrimaryKey = policyPrimaryKey
        self.policySecondaryKey = policySecondaryKey
    }
    
    func isEmpty() -> Bool {
        return self.url.isEmpty || self.policySecondaryKey.isEmpty || self.policyPrimaryKey.isEmpty || self.policyName.isEmpty || self.consumerGroup.isEmpty
    }
}

// MARK: - WFEventHubClient
private(set) var sharedClient: WFEventHubClient = WFEventHubClient()
class WFEventHubClient {
    private var authorization: WFEventHubAuthorization = WFEventHubAuthorization()
    
    init() {
        
    }
    
    /**
     This sets the authorization information for the client. This must be done before any events are sent
     - Throws: error code 1 ("Invalid Credentials") if any authorization strings are empty
     */
    func setAuthorization(authorization a: WFEventHubAuthorization) throws {
        self.authorization = a
        sharedClient = self
        if a.isEmpty() {
            throw WFError(code: 1, message: "Invalid Credentials")
        }
    }
    
    private func getSASToken() throws {
        if self.authorization.isEmpty() == true {
            throw WFError(code: 1, message: "Invalid Credentials")
        }
        else {
            let now: NSDate = NSDate()
        }
    }
    
    private func makeHeaders(additionalHeaders: [String: String]?) -> [String: String] {
        var headers: [String: String] = [String: String]()
        if authorization.isEmpty() == false {
            headers = [
                "Authorization" : "",
                "Content-Type" : "",
                "Host": ""
            ]
            for h in additionalHeaders ?? [String: String]() {
                headers[h.0] = h.1
            }
        }
        return headers
    }
    
    func sendEvent(event: WFEvent) {
//        Alamofire.request(Method.POST, self.authorization.url, parameters: <#T##[String : AnyObject]?#>, encoding: <#T##ParameterEncoding#>, headers: <#T##[String : String]?#>)
    }
    
}