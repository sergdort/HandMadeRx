//: Playground - noun: a place where people can play

import UIKit

let observable = Observable<Int> { (observer) -> Disposable in
    observer.on(event: .next(1))
    observer.on(event: .next(2))
    observer.on(event: .next(3))
    observer.on(event: .completed)
    return AnonimousDisposable {
        print("disposed")
    }
}

observable.map {
        return $0 * $0
    }
    .subscribe {
        print($0)
    }
