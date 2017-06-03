import Foundation

public protocol ObservableType {
    associatedtype E
    
    func subscribe<O: ObserverType>(observer: O) -> Disposable where O.E == E
}

public class Observable<Element>: ObservableType {
    public typealias E = Element
    private let _subscribeHandler: (Observer<Element>) -> Disposable
    
    public init(_ subscribtionClosure: @escaping (Observer<Element>) -> Disposable) {
        _subscribeHandler = subscribtionClosure
    }
    
    public func subscribe<O : ObserverType>(observer: O) -> Disposable where O.E == E {
        let sink = Sink(forvard: observer, subscribtionHandler: _subscribeHandler)
        sink.run()
        return sink
    }
}

extension ObservableType {
    public func subscribe(onNext: @escaping (E) -> Void) -> Disposable {
        return subscribe(observer: Observer { (event) in
            switch event {
            case .next(let element):
                onNext(element)
            default:
                break
            }
        })
    }
    
    public static func just(_ value: E) -> Observable<E> {
        return Observable { (observer) -> Disposable in
            observer.on(event: .next(value))
            observer.on(event: .completed)
            return NopeDisposable()
        }
    }
    
    public func map<U>(_ transform: @escaping (E) throws -> U) -> Observable<U> {
        return Observable<U> { observer in
            return self.subscribe(observer: Observer { (event) in
                switch event {
                case .next(let element):
                    do {
                        try observer.on(event: .next(transform(element)))
                    } catch {
                        observer.on(event: .error(error))
                    }
                case .error(let e):
                    observer.on(event: .error(e))
                case .completed:
                    observer.on(event: .completed)
                }
            })
        }
    }
    
    public func flatMap<U>(_ transfrom: @escaping (E) -> Observable<U>) -> Observable<U> {
        return Observable({ (observer) -> Disposable in
            return self.subscribe(observer: Observer { (event) in
                let composite = CompositeDisposable()
                switch event {
                case .next(let element):
                    let transformed = transfrom(element)
                    let disposable = transformed.subscribe(observer: Observer { _event in
                        switch _event {
                        case .next(let e):
                            observer.on(event: .next(e))
                        case .error(let err):
                            observer.on(event: .error(err))
                            composite.dispose()
                        case .completed:
                            observer.on(event: .completed)
                            composite.dispose()
                        }
                    })
                    composite.add(disposable: disposable)
                case .error(let e):
                    observer.on(event: .error(e))
                    composite.dispose()
                case .completed:
                    observer.on(event: .completed)
                    composite.dispose()
                }
            })
        })
    }
    
}
