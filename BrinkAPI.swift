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
    var time : Double = 0
    var duration : Double = 0
    var startCoordinateX : Double = 0.0
    var startCoordinateY : Double = 0.0
    var endCoordinateX : Double = 0.0
    var endCoordinateY : Double = 0.0
    var maxAltitude : Double = 0
    var minTemperature : Double = 0
    var maxTemperature : Double = 0
}

class BrinkFlightDataPoint {
    var timestamp : Double = 0.0
    var coordinateX : Double = 0.0
    var coordinateY : Double = 0.0
    var pressure : Double = 0.0
    var temperature : Double = 0.0
    var altitude : Double = 0.0
    
    func toDictionary() -> [String : Any] {
        var resultDict = [String : Any]()
        resultDict["timestamp"] = self.timestamp
        resultDict["altitude"] = self.altitude
        resultDict["pressure"] = self.pressure
        resultDict["coordinateX"] = self.coordinateX
        resultDict["coordinateY"] = self.coordinateX
        resultDict["temperature"] = self.temperature
        
        return resultDict
    }
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
            guard let responseDict = response as? [String : Any],
                let time = responseDict["flightTime"] as? Double,
                let duration = responseDict["duration"] as? Double,
                let startCoordinateX = responseDict["startCoordinateX"] as? Double,
                let startCoordinateY = responseDict["startCoordinateY"] as? Double,
                let endCoordinateX = responseDict["endCoordinateX"] as? Double,
                let endCoordinateY = responseDict["endCoordinateY"] as? Double,
                let maxAltitude = responseDict["maxAltitude"] as? Double,
                let minTemperature = responseDict["minTemperature"] as? Double,
                let maxTemperature = responseDict["maxTemperature"] as? Double
                else {
                    if let err = error {
                        completion?(nil, err)
                    } else {
                        let error = NSError(domain: self.errorDomain, code: self.errorCode, userInfo: [NSLocalizedDescriptionKey : "Some needed fields not present in the response"])
                        completion?(nil, error)
                    }
                    return
            }
            
            let flight = BrinkFlight()
            flight.time = time
            flight.duration = duration
            flight.startCoordinateX = startCoordinateX
            flight.endCoordinateX = endCoordinateX
            flight.startCoordinateY = startCoordinateY
            flight.endCoordinateY = endCoordinateY
            flight.maxAltitude = maxAltitude
            flight.minTemperature = minTemperature
            flight.maxTemperature = maxTemperature
            
            completion?(flight, nil)
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
    
    func getFlightData(flightId : Int, page : Int, perPage : Int, completion : ((_ flightDataPoints : [BrinkFlightDataPoint], _ error : Error?) -> ())?) {
        self.brinkAPICall(method: BrinkAPIMethod.getFlightData, dataJsonObject: ["page" : page, "perPage" : perPage], urlParameters: [String(flightId)]) { (response, error) in
            
            guard let responseDict = response as? [String : Any], let dataDict = responseDict["data"] as? [[String : Any]] else {
                if let err = error {
                    completion?([], err)
                } else {
                    let error = NSError(domain: self.errorDomain, code: self.errorCode, userInfo: [NSLocalizedDescriptionKey : "Response is not in the correct format"])
                    completion?([], error)
                }
                return
            }
            
            var flightDataPoints = [BrinkFlightDataPoint]()
            
            for aFlightPointDict in dataDict {
                guard let timestamp = aFlightPointDict["timestamp"] as? Double,
                    let coordinateX = aFlightPointDict["coordinateX"] as? Double,
                    let coordinateY = aFlightPointDict["coordinateY"] as? Double,
                    let pressure = aFlightPointDict["pressure"] as? Double,
                    let temperature = aFlightPointDict["temperature"] as? Double,
                    let altitude = aFlightPointDict["altitude"] as? Double else {
                        continue
                }
                
                let dataPoint = BrinkFlightDataPoint()
                dataPoint.timestamp = timestamp
                dataPoint.coordinateX = coordinateX
                dataPoint.coordinateY = coordinateY
                dataPoint.pressure = pressure
                dataPoint.temperature = temperature
                dataPoint.altitude = altitude
                
                flightDataPoints.append(dataPoint)
            }
            
            completion?(flightDataPoints, nil)
        }
    }
    
    func createFlightDataPoint(flightId : Int, dataPoint : BrinkFlightDataPoint, completion : ((_ error : Error?) -> ())?) {
        self.brinkAPICall(method: BrinkAPIMethod.createFlightDataRecord, dataJsonObject: dataPoint.toDictionary(), urlParameters: [String(flightId)]) { (response, error) in
            completion?(error)
        }
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
            print("API call: \n\(finalUrlString)\nMethod: \(httpMethod.rawValue)\nHeaders: \(String(describing: urlRequest.allHTTPHeaderFields))\nBody: \(postJsonString ?? "nil")\n\n")
            
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


