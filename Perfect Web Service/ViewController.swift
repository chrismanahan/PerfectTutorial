//
//  ViewController.swift
//  Perfect Web Service
//
//  Created by Chris M on 2/15/16.
//  Copyright © 2016 Christopher Manahan. All rights reserved.
//

import UIKit
import PerfectLib

let WS_HOST = "localhost"
let WS_PORT = 8181

class ViewController: UIViewController {

    @IBOutlet var outputTextview: UITextView!
    @IBOutlet var inputTextField: UITextField!
    
    @IBAction func getPost(sender: AnyObject) {
        getRandomPost()
    }
    
    @IBAction func sendPost(sender: AnyObject) {
        if let text = inputTextField.text {
            postContent(text)
        }
    }
    
    // MARK: - Web Service
    func postContent(content: String) {
        do {
            print("creating request for content: \(content)")
            let req = NSMutableURLRequest(URL: NSURL(string: postEndpoint())!)
            // set request headers
            req.HTTPMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // make json packet
            let je = JSONEncoder()
            let json = try je.encode(["content": content])
            
            // set request body
            req.HTTPBody = json.dataUsingEncoding(NSASCIIStringEncoding)
            
            // send the request
            print("sending request \(req)")
            let sesh = NSURLSession.sharedSession()
            let task = sesh.dataTaskWithRequest(req, completionHandler: {
                (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                
                if error != nil {
                    print("error: \(error)")
                }
                
                print(response)
            })
            
            task.resume()
            
            inputTextField.text = ""
            
        } catch {
            print("ERROR POSTING CONTENT")
        }
    }
    
    func getRandomPost() {
        //open url session
        let sesh = NSURLSession.sharedSession()
        let task = sesh.dataTaskWithURL(NSURL(string: postEndpoint())!) { [weak self] data, response, error in
            // make sure we have data. if we don't, the web service might not be running, or you're hitting the wrong endpoint
            guard let data = data else {
                print("no data")
                return
            }
            
            do {
                // decode the json
                let string = String(data: data, encoding: NSASCIIStringEncoding)!
                let jd = JSONDecoder()
                let json = try jd.decode(string) as! JSONDictionaryType
                let content = json.dictionary["content"] as! String
                
                // we must be on the main thread to modify UI
                dispatch_async(dispatch_get_main_queue()) {
                    self?.outputTextview.text = content
                }
                
            } catch {
                print("error getting posts")
            }
        }
        
        task.resume()
    }
    
    func postEndpoint() -> String {
        return "http://\(WS_HOST):\(WS_PORT)/posts"
    }
}

