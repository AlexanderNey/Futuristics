# Futuristics
[![Twitter: @ajax64](https://img.shields.io/badge/Author-Alexander%20Ney-00B893.svg)](https://twitter.com/ajax64)
![Platform](https://img.shields.io/cocoapods/v/Futuristics.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Platform](https://img.shields.io/cocoapods/p/Futuristics.svg)
![License](https://img.shields.io/cocoapods/l/Futuristics.svg)
![Travis](https://img.shields.io/travis/AlexanderNey/Futuristics.svg)
[![Swift Version](https://img.shields.io/badge/Swift-2.1-F16D39.svg?style=flat)](https://developer.apple.com/swift)

This library adds the concept of [Promises / Futures](https://en.wikipedia.org/wiki/Futures_and_promises) to Swift with the goal of making asynchronous code easy to handle. Futures are simply a value type representing the notion of a value that is yet to be computed.


✔️ Fully Unit tested
✔️ 100% Swift
✔️ Supports Error Handling
✔️ Type Safety
✔️ Composable
✔️ Thread Safe



## Installation

Futuristics is available through [Carthage](https://github.com/Carthage/Carthage) or [CocoaPods](https://cocoapods.org).

### Carthage

To install Futuristics with Carthage, add the following line to your `Cartfile`.

    github "AlexanderNey/Futuristics" "0.2.2"


Then run `carthage update`. For details of the installation and usage of Carthage, visit [its project page](https://github.com/Carthage/Carthage).


### CocoaPods

To install Futuristics with CocoaPods, add the following lines to your `Podfile`.

    source 'https://github.com/CocoaPods/Specs.git'
    platform :ios, '8.0'
    use_frameworks!

    pod 'Futuristics', '0.2.2'

Then run `pod install` command. For details of the installation and usage of CocoaPods, visit [its official website](https://cocoapods.org).


## Asynchronous Code Without Futures
Just some asynchronous code with proper error handling in Swift 2.x
```swift
let client = NetworkClient()
let request = NSURLRequest(URL: NSURL(string: "http://foo.com/bar")!)
client.exectueRequest(request) { response, error in
    if error != nil {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            do {
                let json = try self.jsonFromResponse(response)
                let name = try self.extractNameFromJSON(json)
                dispatch_async(dispatch_get_main_queue(),{
                    self.updateUIWithName(name)
                })
            } catch let error {
                dispatch_async(dispatch_get_main_queue(),{
                    self.displayError(error)
                })
            }
        }
    } else {
        dispatch_async(dispatch_get_main_queue(),{
            self.displayError(error!)
        })
    }
}
```

Ok ok... I am maybe exaggerating. But you get the idea - it is bloated!


## Futures To The Rescue
With futures the code can be much leaner and intuitive.

```swift
let client = NetworkClient()
let request = NSURLRequest(URL: NSURL(string: "http://foo.com/bar")!)

let requestAndParse = client.exectueRequest >>> onBackgroundQueue(self.jsonFromResponse >>> self.extractNameFromJSON)
requestAndParse(request).onSuccess(onMainQueue) { name in
    self.updateUIWithName(name)
}.onFailure(onMainQueue) { error in
    self.displayError(error)
} }
```

There are a few differences to the non future example above:
1. the `executeRequest` function now receives a `NSRULRequest` and returns a `Future<NSURLResponse>` that is a future value of NSURLResponse 
2. `requestAndParse` is a composition of `exectueRequest`, `jsonFromResponse` and `extractNameFromJSON` - the signature of this function now is `NSURLRequest -> Future<String>`
4. `jsonFromResponse` and `extractNameFromJSON` are made explicitly asynchronous by wrapping them in the `onBackgroundQueue` function
5. the `onSuccess` and `onFailure` closures are are executed depending on the result of the Future determined by the function `requestAndParse`
5. the completion blocks execution are explicitly set to take place on the main queue by invoking them with the execution context `onMainQueue`

All concepts are described below.


## Future & Promise
In order to create a function that returns a Future you have to create a Promise first. A Promise represents pretty much a notion of the aim to compute the value. A promise can be fulfilled or rejected and shouldn't be exposed to any scope unrelated to the computation of the Future value. Promises can be mutated where whereas Future values are always immutable. In other words yor function creates the Promise, takes care of the fulfilment but returns only the Future of the Promise as an immutable read only value. Promises and Futures are sharing a common set of states:

**Pending** - Represents the initial state when the Future value is to be computed

**Fulfilled / Rejected** - The final state which indicates either a successful computation of the value or a failure. Those states contain either the concrete value or an Swift `ErrorType` that represents the failure reason.

Note that you can't create Futures only Promises. Promises are always typed (hello Generics). Futures have always the same type as their related Promises.


## Asynchronous Functions

Lets make a somewhat more concrete example:

```swift
func exectueRequest(request: NSURLRequest) -> Future<NSURLResponse> {
        // Create a promise
        let promise = Promise<NSURLResponse>()
        // asynchronous code block start
            // If operation fails
            promise.reject(error)
        
            // OR
        
            // If operation succeeds
            promise.fulfill(response)
        // asynchronous code block end
        
        return promise.future
    }

```

In order to return the Future you have to create a typed Promise with the expected value type NSURLResponse. The function will immediately return the future of the created Promise and probably delay some asynchronous code to fulfil or reject the Promise. You can only either fulfil or reject the Promise once. 

Not that you can also fulfil the Promise (synchronously) before returning its future. The scope above will immediately get a Future that is fulfilled.


## Completion Handlers

Futures can have completion handlers assigned. There are three possible type of handlers which can be chained arbitrary.

```onSuccess: T -> Void``` - value of T is the type of the Future; executed only if the Promise was successfully resolved

```onFailure: ErrorType -> Void``` - arbitrary ErrorType; executed only of the Promise was rejected

```finally: Void -> Void``` - executed after the Promise was either failed or rejected and is more for tasks where you don't care about the result. Usually this is used in conjunction with the other handlers.

Note: Circular references must be avoided for completion handlers much like with every other retained closure.

You can also chain multiple handlers of the same type and attach them at every state of the Future. If you attach a handler to a fulfilled or rejected state the completion handler will be executed immediately.


#### Example

```swift
self.showLoadingUI()

requestAndParse(request).onSuccess { name in
    self.displayName(name)
}.onFailure { error in
    self.displayError(error)
}.finally {
    hideLoadingUI
}
```

In that example we made good use of `finally` to e.g. dismiss the loading state of the UI which we previously may have activated to visually indicate an ongoing network request.



## Composing Asynchronous Functions

For the sake of readability functions with the following signature can be chained together:
```A -> Future<B>```  AND ```B -> Future<C>``` 
The result of type B of the first function will be then used as a argument for the second function to compute a value of type C so the resulting function will have a type of:
```A -> Future<C>``` 
Chaining is realised with the **>>>** operator.

With this you could chain multiple Future returning functions together.

#### Example

```swift

func exectueRequest(request: NSURLRequest) -> Future<NSURLResponse> { ... }
func parseResponse(response: NSURLResponse) -> Future<String> { ... }
    

let request = NSURLRequest( ... )
let requestAndParse = exectueRequest >>> parseResponse
requestAndParse(request).onSuccess { text in
	print(text)
}
```


## Make Synchronous Functions Asynchronous

Sometimes a function should not care in which thread or queue it is executed to have a better separation of concerns and create more reusable code. For this Futuristics provides some wrapper functions also referred to as the **Execution Context**. Simply put a regular function like ```A throws -> B``` as an argument and the resulting function will be of type ```A -> Future<B>```. More about Execution Contexts [below](## Execution Context).

### Example

```swift
func parseResponseSynch(response: NSURLResponse) -> String { ... }
let parseResponseOnBackground = onBackgroundQueue(parseResponseSynch)
```


## Execution Context

You can use any of the following included Execution Contexts

####onMainQueue
execute on the main queue synchronous if called from it or asynchronous if called from another queue

####onBackgroundQueue 
execute on a well known background queue - perfect if you just want to avoid blocking the main thread - equivalent to dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

####onQueue(queue: dispatch_queue_t)
execute on a specified queue

The implementation of the included Execution Contexts is based on GCD but you can create any custom context you desire by simply following function signature: ```(A -> throws B) -> (A -> Future<B>)```.

Note that the Execution Context will convert any throwable function to a non throwable one as the Future will represent any occurring errors (see rejected state).

## Error Handling

As mentioned before a Future can either be fulfilled or rejected. A rejected Future conveys a failure of the computation operation that returned the Future. In this case the Future carries the failure reason as an arbitrary `ErrorType`.

Functions that return a Future should not throw - instead they should reject the Promise to transport the error to the scope above.

Functions that where generated by an Execution Context will internally catch any error that was thrown by the origin function and automatically reject the Promise incl. its Future.

### Example

```swift
enum ParserError : ErrorType {
	case InvalidJSON
    // ...
}

func parseResponseSynch(response: NSURLResponse) throws -> String {
    throw ParserError.InvalidJSON
}

let parseResponseOnBackground = onBackgroundQueue(parseResponseSynch)

parseResponseOnBackground().onFailure { error in 
	println("Will always fail with ParserError.InvalidJSON")
	
}
```


## License

MIT license. See the [LICENSE file](LICENSE.txt) for details.

