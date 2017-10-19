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

class BrinkUser {
    var email : String = ""
    var firstName : String = ""
    var lastName : String = ""
    var userName : String = ""
    var userId : Int = 0
}

class BrinkFlight {
    var id : Int = 0
    var time : Int? = nil
    var duration : Int? = nil
    var startCoordinateX : Double? = nil
    var startCoordinateY : Double? = nil
    var endCoordinateX : Double? = nil
    var endCoordinateY : Double? = nil
    var maxAltitude : Int? = nil
    var minTemperature : Int? = nil
    var maxTemperature : Int? = nil
}

class BrinkFlightDataPoint {
    
}

class BrinkAPI {
    
    private let errorDomain = "com.brinkapierrordomain"
    private let errorCode = 123
    
    private var urlSession : URLSession? = nil
    
    var accessToken : String? = nil
    
    //MARK: - Lifecycle
    
    init(jwtToken : String? = nil) {
        self.accessToken = jwtToken
    }
    
    //MARK: - Public
    
    func createUser(firstName : String, lastName : String, email : String, username : String, password : String, completion : ((_ jwtToken : String?, _ userId : Int?, _ error : Error?) -> ())?) {
        let parameters = ["first_name" : firstName, "last_name" : lastName, "email" : email, "username" : username, "password" : password]
        self.brinkAPICall(method: BrinkAPIMethod.createUser, dataJsonObject: parameters, urlParameters: []) { (response, error) in
            
            guard let responseDict = response as? [String : Any], let token = responseDict["jwt_token"] as? String, let userId = responseDict["user_id"] as? Int else {
                if let err = error {
                    completion?(nil, nil, err)
                } else {
                    let error = NSError(domain: self.errorDomain, code: self.errorCode, userInfo: [NSLocalizedDescriptionKey : "Empty response"])
                    completion?(nil, nil, error)
                }
                return
            }
            
            self.accessToken = token
            
            completion?(token, userId, nil)
        }
    }
    
    func getUser(userId : Int, completion : ((_ user : BrinkUser?, _ error : Error?) -> ())?) {
        self.brinkAPICall(method: BrinkAPIMethod.getUser, dataJsonObject: nil, urlParameters: [String(userId)]) { (response, error) in
            guard let responseDict = response as? [String : Any],
                let email = responseDict["email"] as? String,
                let username = responseDict["username"] as? String,
                let firstName = responseDict["first_name"] as? String,
                let lastName = responseDict["last_name"] as? String,
                let userId = responseDict["id"] as? Int
                else {
                    if let err = error {
                        completion?(nil, err)
                    } else {
                        let error = NSError(domain: self.errorDomain, code: self.errorCode, userInfo: [NSLocalizedDescriptionKey : "Empty response"])
                        completion?(nil, error)
                    }
                    return
            }
            
            let user = BrinkUser()
            user.email = email
            user.userName = username
            user.firstName = firstName
            user.lastName = lastName
            user.userId = userId
            
            completion?(user, nil)
        }
    }
    
    func login(username : String, password : String, completion : ((_ user : BrinkUser?, _ error : Error?) -> ())?) {
        let parameters = ["username" : username, "password" : password]
        self.brinkAPICall(method: BrinkAPIMethod.login, dataJsonObject: parameters, urlParameters: []) { (response, error) in
            guard let responseDict = response as? [String : Any],
                let email = responseDict["email"] as? String,
                let username = responseDict["username"] as? String,
                let firstName = responseDict["first_name"] as? String,
                let lastName = responseDict["last_name"] as? String,
                let userId = responseDict["id"] as? Int,
                let jwtToken = responseDict["jwt_token"] as? String
                else {
                    if let err = error {
                        completion?(nil, err)
                    } else {
                        let error = NSError(domain: self.errorDomain, code: self.errorCode, userInfo: [NSLocalizedDescriptionKey : "Empty response"])
                        completion?(nil, error)
                    }
                    return
            }
            
            self.accessToken = jwtToken
            
            let user = BrinkUser()
            user.email = email
            user.userName = username
            user.firstName = firstName
            user.lastName = lastName
            user.userId = userId
            
            completion?(user, nil)
        }
    }
    
    func getAllFlightIds(completion : ((_ flightIds : [Int], _ error : Error?) -> ())?) {
        self.brinkAPICall(method: BrinkAPIMethod.getAllFlights, dataJsonObject: nil, urlParameters: []) { (response, error) in
            guard let responseDict = response as? [String : Any],
                let flightIds = responseDict["flights"] as? [Int]
                else {
                    if let err = error {
                        completion?([], err)
                    } else {
                        let error = NSError(domain: self.errorDomain, code: self.errorCode, userInfo: [NSLocalizedDescriptionKey : "Empty response"])
                        completion?([], error)
                    }
                    return
            }
            
            completion?(flightIds, nil)
        }
    }
    
    func getFlight(flightId : Int, completion : ((_ flight : BrinkFlight?, _ error : Error?) -> ())?) {
        self.brinkAPICall(method: BrinkAPIMethod.getFlight, dataJsonObject: nil, urlParameters: [String(flightId)]) { (response, error) in
            
        }
    }
    
    func createFlight(completion : ((_ flightId : Int?, _ error : Error?) -> ())?) {
        self.brinkAPICall(method: BrinkAPIMethod.createFlight, dataJsonObject: nil, urlParameters: []) { (response, error) in
            guard let responseDict = response as? [String : Any],
                let flightId = responseDict["id"] as? Int
                else {
                    if let err = error {
                        completion?(nil, err)
                    } else {
                        let error = NSError(domain: self.errorDomain, code: self.errorCode, userInfo: [NSLocalizedDescriptionKey : "Empty response"])
                        completion?(nil, error)
                    }
                    return
            }
            
            completion?(flightId, nil)
        }
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
        
        var finalUrlString = urlString
        
        if urlParameters.count > 0 {
            finalUrlString = String(format: urlString, arguments: urlParameters)
        }
        
        if let url = URL(string: finalUrlString) {
            
            //Create the session configuration and the session if needed
            if self.urlSession == nil {
                let sessionConfiguration = URLSessionConfiguration.default
                self.urlSession = URLSession(configuration: sessionConfiguration)
            }
            
            
            //Build up the url request
            var urlRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 5.0)
            urlRequest.httpMethod = httpMethod.rawValue
            urlRequest.allHTTPHeaderFields = httpHeaders
            //            urlRequest.allHTTPHeaderFields = [String:String]()
            //            urlRequest.allHTTPHeaderFields?["Content-Type"] = "application/json"
            
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
            print("API call: \n\(finalUrlString)\nMethod: \(httpMethod.rawValue)\nHeaders: \(String(describing: urlRequest.allHTTPHeaderFields))\nBody: \(String(describing: postJsonString))\n\n")
            
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

