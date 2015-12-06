# Futuristics
[![Twitter: @ajax64](https://img.shields.io/badge/Author-Alexander%20Ney-00B893.svg)](https://twitter.com/ajax64)
![Platform](https://img.shields.io/cocoapods/v/Futuristics.svg)
![Platform](https://img.shields.io/cocoapods/p/Futuristics.svg)
![License](https://img.shields.io/cocoapods/l/Futuristics.svg)
![Travis](https://img.shields.io/travis/AlexanderNey/Futuristics.svg)


This library adds [Promises / Futures](https://en.wikipedia.org/wiki/Futures_and_promises) to Swift with the goal making asynchronous code easy to handle. Futures are simply a value type representing the notion of a value that is yet to be determined - much like an Optional represents an optional value.


✔️ Fully Unit tested
✔️ 100% Swift
✔️ Error Handling
✔️ Type Safety
✔️ Composable

## Asynchronous Code Without Futures
Just some asynchronous code with proper error handling in Swift 2.0
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

Ok ok... I am maybe exaggerating. But you get the idea...

## Futures To The Rescue
With futures the code can be much leaner and intutive.

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
1. the `executeRequest` function now receives a `NSRULRequest` and returns a `Future<NSURLResponse>`
2. `requestAndParse` is a composition of `exectueRequest`, `jsonFromResponse` and `extractNameFromJSON` - the type of this function now is `NSURLRequest -> Future<String>`!
4. `jsonFromResponse` and `extractNameFromJSON` are made explicity asynchronous by wrapping them in the `onBackgroundQueue` function
5. `onSuccess` and `onFailure` are the compltion blocks that are executed depending on the state of the whole function chain encapusled in `requestAndParse`
5. the completion blocks execution are explicitly set to take place on the main queue by invoking them with `onMainQueue`

## Future & Promise
In order to create a function that returns a Future you have to create a Promise first. A Promise is pretty much a notion of the aim to compute a value after some delay. Promises are holding their Future value which then represents that computed value. A promise can be fulfilled or rejected and shouldn't be exposed to any scope unrelated to the computation of the final value. In other words yor function creates the Promise, takes care of the fulfillment or rejection but returns only the Future of the Promise as an immutable read only value. Promises and Futures are sharing a common set of states:

*Pending* - Represents the initial state when the Future value is to be computed

*Fulfilled / Rejected* - The final state which indicates either a successful compoutation of the value or a failure. Those states contain either the concrete value or an Swift `ErrorType` that represents the failure reason.

## Asynchronous Functions
Lets make a somewhat more concrete exmaple:
```swift
func exectueRequest(request: NSURLRequest) -> Future<NSURLResponse> {
        // Create a pormise
        let promise = Promise<NSURLResponse>()
        // asynchronous code block start
            // If operation failes
            promise.reject(error)
        
            // OR
        
            // If operation succeeds
            promise.fulfill(response)
        // asynchronous code block end
        
        return promise.future
    }

```

In order to return the Future you have to create a typed Promise with the expected value type NSURLResponse. The function will imediately return the future of the created Promise and probably delay some asynchonous code to fulfill or reject the Promise. You can only either fulfill or reject the Promise once.

## Completion Handlers
Futures can have completion handlers attached. There are three possible handlers which can be chained arbitrary.

```swift onSuccess: T -> Void``` - value of T is the type of the Future; executed only if the Promise was succesfully resolved

```swift onFailure: ErrorType -> Void``` - arbitrary ErrorType; executed only of the Promise was rejected

```swift finally: Void -> Void``` - executed after the Promise was either failed or rejected and is more for tasks where you don't care about the result. Usually this is used in conjunction with the other handlers.


### Example

```swift
self.loadingUI(true)
requestAndParse(request).onSuccess { name in
    self.displayName(name)
}.onFailure { error in
    self.displayError(error)
}.finally {
    self.loadingUI(false)
}
```

In that example we made good use of `finally` to e.g. return from the loading state of the UI which we previosly may have activated to visually indicate an ongoing network request.



## Composing Asynchronous Functions

For the sake of readability functions with the following type can be chained together:
```swift A -> Future<B>```  AND ```swift B -> Future<C>``` 
The result of type B of the first function will be then used as a argument of the second function to compute a value of type C so the resulting function will have a type of:
```swift A -> Future<C>``` 
Chaining is realised with the **>>>** operator.

### Example

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
Ideally a function should not care in which thread or queue it is executed to have a better separation of concerns and create more resuable code. For this Futuristics provides some wrapper functions also reffered to as the **Execution Context**. Simply put a regalar function like ```swift A throws -> B``` as an argument and the resulting function will be of type ```swift A -> Future<B>```. More about Execution Contexts below

## Example
```swift
func parseResponseSynch(response: NSURLResponse) -> String { ... }
let parseResponseOnBackground = onBackgroundQueue(parseResponseSynch)
```

## Execution Context

You can use any of the following included Execution Contexts
```swift
onMainQueue // execute on the main queue synchronous if called from it or asynchronous if called from another queue
onBackgroundQueue // execute on a well known background queue - perfect if you just want to avoid blocking the main thread - equvalent to dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
onQueue(queue: dispatch_queue_t) // execute on a sepcified queue
```
The implementation of the included Execution Contexts is based on GCD but you can create any custom context you desire by simply folllowing the pattern ```swift (A -> throws B) -> (A -> Future<B>)```.


## Error Handling

As meantioned before a Future can either be fulfilled or rejected. A rejected Future conveys a failure of the computation operation that returned the Future by containing the failure reason as an arbitrary `ErrorType`.

Functions that return a Future should not thorw - instead they should reject the Promise to transport the error to the scope above.

However functions that where generated with the Execution Context will internally catch any error that was thrown by the origin function and automatically reject the Promise which then results in a rejected Future.

## Example

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


## Coposing Functions
