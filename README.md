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

## Asynchronous code without Futures
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

## Futures to the rescue
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


## Asynchronous Functions

## Completion Handlers

## Composing Asynchronous Functions

## Make Synchronous Functions Asynchronous

## Execution Context

## Error Handling

## Coposing Functions
