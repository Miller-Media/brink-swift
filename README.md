<img src="http://joinbrink.com/assets/images/repo/Brink.png?"><img src="http://joinbrink.com/assets/images/repo/Swift-logo.png">

# Brink Swift Wrapper

## Installation
Copy the BrinkAPI.swift file to your project.

## Usage

### Instantiate a BrinkAPI object

```swift
    let brinkAPI = BrinkAPI()
```

Optionally you can set an access token to the instance:

```swift
    brinkAPI.accessToken = "access_token_string"
```

Note that the responses are not yet handled by the BrinkAPI instance. They need to be handled in the completion handlers of each request.


### Create new user

```swift
    brinkAPI.createUser(firstName: "firstName", lastName: "lastName", email: "example@example.com", username: "username", password: "password") { (response, error) in
        //Parse response json dictionary object
    }
```
This API call does not require an access token.

### Get an existing user

```swift
    brinkAPI.getUser(userId: "user_id") { (response, error) in
        //Parse response json dictionary object
    }
```
This API call does not require an access token.

### Login

```swift
    brinkAPI.login(username: "username", password: "password") { (response, error) in
        //Parse response json dictionary object
    }
```
This API call requires an access token to be set on the instance.

### Get all flights

```swift
    brinkAPI.getAllFlights { (response, error) in
        //Parse response json dictionary object
    }
```
This API call requires an access token to be set on the instance.

### Get a specific flight

```swift
    brinkAPI.getFlight(flightId: "flight_id") { (response, error) in
        //Parse response json dictionary object
    }
```
This API call requires an access token to be set on the instance.

### Create a flight

```swift
    brinkAPI.createFlight { (response, error) in
        //Parse response json dictionary object
    }
```
This API call requires an access token to be set on the instance.

### Get flight data

```swift
    brinkAPI.getFlightData(flightId: "flight_id", page: 0, perPage: 20) { (response, error) in
        //Parse response json dictionary object
    }
```
This API call requires an access token to be set on the instance.

### Create flight data

```swift
    brinkAPI.createFlightData(flightId: "flight_id", attributes: ["attr1" : "attr1_value", "attr2" : "attr2_value"]) { (response, error) in
        //Parse response json dictionary object
    }
```
This API call requires an access token to be set on the instance.

## Authors
**Péter Róbert**
