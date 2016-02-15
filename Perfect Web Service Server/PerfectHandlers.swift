//
//  File.swift
//  Perfect Web Service
//
//  Created by Chris M on 2/15/16.
//  Copyright © 2016 Christopher Manahan. All rights reserved.
//

import PerfectLib

let DB_PATH = PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + "PWSDB"


// This function is required. The Perfect framework expects to find this function
// to do initialization
public func PerfectServerModuleInit() {
    
    // Install the built-in routing handler. 
    // This is required by Perfect to initialize everything
    Routing.Handler.registerGlobally()
    
    // register a route for gettings posts
    Routing.Routes["GET", "/posts"] = { _ in
        return GetPostsHandler()
    }
    
    // register a route for creating a new post
    Routing.Routes["POST", "/posts"] = { _ in
        return PostHandler()
    }
    
    do {
        let sqlite = try SQLite(DB_PATH)
        try sqlite.execute("CREATE TABLE IF NOT EXISTS pws (id INTEGER PRIMARY KEY, content STRING)")
    } catch {
        print("Failure creating database at " + DB_PATH)
    }
}

class GetPostsHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        do {
            let sqlite = try SQLite(DB_PATH)
            defer {
                sqlite.close()  // defer ensures we close our db connection at the end of this request
            }
            
            // query the db for a random post
            try sqlite.forEachRow("SELECT content FROM pws ORDER BY RANDOM() LIMIT 1") {
                (statement: SQLiteStmt, i:Int) -> () in
                
                do {
                    let content = statement.columnText(0)
                    
                    // encode the random content into JSON
                    let jsonEncoder = JSONEncoder()
                    let respString = try jsonEncoder.encode(["content": content])
                    
                    // write the JSON to the response body
                    response.appendBodyString(respString)
                    response.addHeader("Content-Type", value: "application/json")
                    response.setStatus(200, message: "OK")
                } catch {
                     response.setStatus(400, message: "Bad Request")
                }
            }
            
        } catch {
            response.setStatus(400, message: "Bad Request")
        }
        
        response.requestCompletedCallback()
    }
}

class PostHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        let reqData = request.postBodyString    // get the request body
        let jsonDecoder = JSONDecoder() // JSON decoder
        do {
            // decode(_:) returns a JSONValue, which is just an alias to Any
            // because we know the request will be a dictionary, we can just force
            // the downcast to JSONDictionaryType. In a real production web service,
            // you would include error checking here to validate the request that it is what 
            // we expect. For the purpose of this tutorial, we're gonna lean 
            // on the side of danger
            let json = try jsonDecoder.decode(reqData) as! JSONDictionaryType
            print("received request JSON: \(json.dictionary)")
            
            let content = json.dictionary["content"] as? String    // again, error check is VERY important here

            guard content != nil else {
                // bad request, bail out
                response.setStatus(400, message: "Bad Request")
                response.requestCompletedCallback()
                return
            }
            
            // put the content into our db
            let sqlite = try SQLite(DB_PATH)
            defer {
                sqlite.close()  // defer ensures we close our db connection at the end of this request
            }
            
            try sqlite.execute("INSERT INTO pws (content) VALUES (?)", doBindings: {
                (statement: SQLiteStmt) -> () in
                
                try statement.bind(1, content!) // this binds our input string to the first ? in the query
            })
            
            response.setStatus(201, message: "Created")
        } catch {
            print("error decoding json from data: \(reqData)")
            response.setStatus(400, message: "Bad Request")
        }
        
        // this completes the request and sends the response to the client
        response.requestCompletedCallback()
    }
}