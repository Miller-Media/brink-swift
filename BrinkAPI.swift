//
//  BrinkAPI.swift
//  
//
//  Created by Peter Robert on 21/09/2017.
//

import Foundation

typealias APICompletionClosure = (_ responseJsonObject : Any?, _ error : Error?) -> ()

enum HttpMethod : String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum BrinkAPIMethod {
    
    case createUser
    case getUser
    case login
    case getAllFlights
    case getFlight
    case createFlight
    case getFlightData
    case createFlightDataRecord
    
    func apiUrlString() -> String {
        let apiBaseUrlString = "http://api.joinbrink.com/v1/"
        
        switch self {
        case .createUser:
            return apiBaseUrlString + "users"
        case .getUser:
            return apiBaseUrlString + "users/%@"
        case .login:
            return apiBaseUrlString + "login"
        case .getAllFlights:
            return apiBaseUrlString + "flights"
        case .getFlight:
            return apiBaseUrlString + "flights/%@"
        case .createFlight:
            return apiBaseUrlString + "flights"
        case .getFlightData:
            return apiBaseUrlString + "flights/%@/data"
        case .createFlightDataRecord:
            return apiBaseUrlString + "flights/%@/data"
        }
    }
    
    func httpMethod() -> HttpMethod {
        switch self {
        case .createUser:
            return .put
        case .getUser:
            return .get
        case .login:
            return .post
        case .getAllFlights:
            return .get
        case .getFlight:
            return .get
        case .createFlight:
            return .put
        case .getFlightData:
            return .post
        case .createFlightDataRecord:
            return .put
        }
    }
    
    func needsAccessToken() -> Bool {
        switch self {
        case .createUser, .login:
            return false
        default:
            return true
        }
    }
}

class BrinkAPI {
    
    private let errorDomain = "com.brinkapierrordomain"
    private let errorCode = 123
    
    private var urlSession : URLSession? = nil
    
    var accessToken : String? = nil
    var userId : String? = nil
    
    //MARK: - Public
    
    func createUser(firstName : String, lastName : String, email : String, username : String, password : String, completion : APICompletionClosure?) {
        let parameters = ["first_name" : firstName, "last_name" : lastName, "email" : email, "username" : username, "passwrod" : password]
        self.brinkAPICall(method: BrinkAPIMethod.createUser, dataJsonObject: parameters, urlParameters: [], completion: completion)
    }
    
    func getUser(userId : String, completion : APICompletionClosure?) {
        self.brinkAPICall(method: BrinkAPIMethod.getUser, dataJsonObject: nil, urlParameters: [userId], completion: completion)
    }
    
    func login(username : String, password : String, completion : APICompletionClosure?) {
        let parameters = ["username" : username, "password" : password]
        self.brinkAPICall(method: BrinkAPIMethod.login, dataJsonObject: parameters, urlParameters: [], completion: completion)
    }
    
    func getAllFlights(completion : APICompletionClosure?) {
        self.brinkAPICall(method: BrinkAPIMethod.getAllFlights, dataJsonObject: nil, urlParameters: [], completion: completion)
    }
    
    func getFlight(flightId : String, completion : APICompletionClosure?) {
        self.brinkAPICall(method: BrinkAPIMethod.getFlight, dataJsonObject: nil, urlParameters: [flightId], completion: completion)
    }
    
    func createFlight(completion : APICompletionClosure?) {
        self.brinkAPICall(method: BrinkAPIMethod.createFlight, dataJsonObject: nil, urlParameters: [], completion: completion)
    }
    
    func getFlightData(flightId : String, page : Int, perPage : Int, completion : APICompletionClosure?) {
        self.brinkAPICall(method: BrinkAPIMethod.getFlightData, dataJsonObject: ["page" : page, "perPage" : perPage], urlParameters: [flightId], completion: completion)
    }
    
    func createFlightData(flightId : String, attributes : [String : Any], completion : APICompletionClosure?) {
        self.brinkAPICall(method: BrinkAPIMethod.createFlightDataRecord, dataJsonObject: attributes, urlParameters: [flightId], completion: completion)
    }
    
    
    //MARK: - Private
    
    private func brinkAPICall(method : BrinkAPIMethod, dataJsonObject : Any?, urlParameters : [String], completion : APICompletionClosure?) {
        
        //Create the headers
        var headers = [String : String]()
        headers["Content-Type"] = "application/json"
        if method.needsAccessToken() {
            if let token = self.accessToken {
                headers["Authorization"] = "JWT \(token)"
            } else {
                let error = NSError(domain: self.errorDomain, code: self.errorCode, userInfo: [NSLocalizedDescriptionKey : "Access token is needed for this API call"])
                completion?(nil,error)
                return
            }
        }
        
        //Make the API call
        self.jsonAPICall(urlString: method.apiUrlString(), httpMethod: method.httpMethod(), httpHeaders: headers, dataJsonObject: dataJsonObject, urlParameters: urlParameters, completion: completion)
    }
    
    private func jsonAPICall(urlString : String, httpMethod : HttpMethod, httpHeaders : [String : String]?, dataJsonObject : Any?, urlParameters : [String], completion : APICompletionClosure?) {
        
        if let url = URL(string: urlString) {
            
            //Create the session configuration and the session if needed
            if self.urlSession == nil {
                let sessionConfiguration = URLSessionConfiguration.default
                self.urlSession = URLSession(configuration: sessionConfiguration)
            }
            
            
            //Build up the url request
            var urlRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 5.0)
            urlRequest.httpMethod = httpMethod.rawValue
            urlRequest.allHTTPHeaderFields = [String:String]()
            urlRequest.allHTTPHeaderFields?["Content-Type"] = "application/json"
            
            var postJsonString : String? = nil
            
            if let postObject = dataJsonObject {
                do {
                    let postData = try JSONSerialization.data(withJSONObject: postObject, options: [])
                    urlRequest.httpBody = postData
                    
                    postJsonString = String(data: postData, encoding: String.Encoding.utf8)
                } catch {
                    let error = NSError(domain: self.errorDomain, code: errorCode, userInfo: [NSLocalizedDescriptionKey : "Couldn't create body data!"])
                    completion?(nil,error)
                    return
                }
            }
            
            //Logs
            print("API call: \n\(urlString)\nMethod: \(httpMethod.rawValue)\nHeaders: \(urlRequest.allHTTPHeaderFields)\nBody: \(postJsonString)\n\n")
            
            //Create the data task
            let task = urlSession?.dataTask(with: urlRequest, completionHandler: { (data, urlResponse, error) in
                if let err = error {
                    completion?(nil,err)
                } else if let responseData = data {
                    
                    if let responseString = String(data: responseData, encoding: String.Encoding.utf8) {
                        print("Response: \(responseString)")
                    }
                    
                    //Create json object from it
                    do {
                        let responseJson = try JSONSerialization.jsonObject(with: responseData, options: [])
                        completion?(responseJson, nil)
                    } catch {
                        
                        let error = NSError(domain: self.errorDomain, code: self.errorCode, userInfo: [NSLocalizedDescriptionKey : "Couldn't create json object from response!"])
                        completion?(nil,error)
                        return
                    }
                }
            })
            task?.resume()
            
        } else {
            let error = NSError(domain: self.errorDomain, code: self.errorCode, userInfo: [NSLocalizedDescriptionKey : "Error constructing URL"])
            completion?(nil,error)
        }
    }
}

