<img src="http://joinbrink.com/assets/images/repo/Brink.png?"><img src="http://joinbrink.com/assets/images/repo/Swift-logo.png">

# Brink Swift Wrapper

## Installation
Copy the BrinkAPI.swift file to your project.

## Usage

### Instantiate a BrinkAPI object

```swift
let brinkAPI = BrinkAPI()
```

### If an access token is available, the BrinkAPI object can be instantiated with it:

```swift
let brinkAPI = BrinkAPI(jwtToken: "tokenString")
```

### Create new user

```swift
brinkAPI.createUser(firstName: "fName", lastName: "lName", email: "email", username: "username", password: "password") { (token, id, error) in
    if let err = error {
        //Handle error
        } else if let jwtToken = token, let userId = id {
            //Handle response
        }
    }
```
This API call does not require an access token.

### Login

```swift
brinkAPI.login(username: "probi", password: "password") { (user, error) in
    if let err = error {
        //Handle error
    } else if let brinkUser = user {
        //Handle user
    }
}
```
This API call does not require an access token.

### Get an existing user

```swift
brinkAPI.getUser(userId: userId) { (user, error) in
    if let err = error {
        //Handle error
    } else {
        //Use user object
    }
}
```
This API call requires an access token to be set on the instance.

### Get all flights

```swift
brinkAPI.getAllFlightIds(completion: { (flightIds, error) in
    if let err = error {
        //Handle error
    } else {
        //Handle returned flight ids
    }
})
```
This API call requires an access token to be set on the instance.

### Get a specific flight

```swift
brinkAPI.getFlight(flightId: flightId, completion: { (flight, error) in
    if let err = error {
        //Handle error
    } else if let brinkFlight = flight {
        //Handle returned flight
    }
})
```
This API call requires an access token to be set on the instance.

### Create a flight

```swift
brinkAPI.createFlight(completion: { (id, error) in
    if let err = error {
        //Handle error
    } else if let flightId = id {
        //Handle flight id
    }
})
```
This API call requires an access token to be set on the instance.

### Get flight data

```swift
brinkAPI.getFlightData(flightId: flightId, page: 1, perPage: 20, completion: { (flightDataPoints, error) in
    if let err = error {
        //Handle error
    } else {
        //Handle array of BrinkFlightDataPoint
    }
})
```
This API call requires an access token to be set on the instance.

### Create flight data

```swift
let flightDataPoint = BrinkFlightDataPoint()
flightDataPoint.timestamp = 1503873412.0
flightDataPoint.altitude = 1234.0
flightDataPoint.pressure = 123123.0
flightDataPoint.coordinateX = 23.234
flightDataPoint.coordinateY = 60.234
flightDataPoint.temperature = 31.0

brinkAPI.createFlightDataPoint(flightId: flightId, dataPoint: flightDataPoint, completion: { (error) in
    if let err = error {
        //Handle error
    }
})
```
This API call requires an access token to be set on the instance.

## Authors
**Péter Róbert**
