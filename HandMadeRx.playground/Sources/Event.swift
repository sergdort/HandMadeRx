
public enum Event<T> {
    case next(T)
    case error(Error)
    case completed
}
