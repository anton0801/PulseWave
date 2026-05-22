import Foundation

final class Promise<Value> {
    
    enum State {
        case pending
        case fulfilled(Value)
        case rejected(Error)
    }
    
    private var state: State = .pending
    private var successHandlers: [(Value) -> Void] = []
    private var failureHandlers: [(Error) -> Void] = []
    private let lock = NSLock()
    
    init() {}
    
    init(_ executor: (@escaping (Value) -> Void, @escaping (Error) -> Void) -> Void) {
        executor(
            { value in self.resolve(value) },
            { error in self.reject(error) }
        )
    }
    
    func resolve(_ value: Value) {
        lock.lock()
        if case .pending = state {
            state = .fulfilled(value)
            let handlers = successHandlers
            successHandlers.removeAll()
            failureHandlers.removeAll()
            lock.unlock()
            
            // На main queue, как ожидают handlers
            if Thread.isMainThread {
                for handler in handlers { handler(value) }
            } else {
                DispatchQueue.main.async {
                    for handler in handlers { handler(value) }
                }
            }
        } else {
            lock.unlock()
        }
    }
    
    func reject(_ error: Error) {
        lock.lock()
        if case .pending = state {
            state = .rejected(error)
            let handlers = failureHandlers
            successHandlers.removeAll()
            failureHandlers.removeAll()
            lock.unlock()
            
            if Thread.isMainThread {
                for handler in handlers { handler(error) }
            } else {
                DispatchQueue.main.async {
                    for handler in handlers { handler(error) }
                }
            }
        } else {
            lock.unlock()
        }
    }
    
    @discardableResult
    func then<NewValue>(_ mapper: @escaping (Value) -> Promise<NewValue>) -> Promise<NewValue> {
        let chained = Promise<NewValue>()
        
        observeFulfilled { value in
            let inner = mapper(value)
            inner.sink { chained.resolve($0) }
            inner.catch { chained.reject($0) }
        }
        observeRejected { chained.reject($0) }
        
        return chained
    }
    
    @discardableResult
    func `catch`(_ handler: @escaping (Error) -> Void) -> Promise<Value> {
        observeRejected(handler)
        return self
    }
    
    @discardableResult
    func sink(_ handler: @escaping (Value) -> Void) -> Promise<Value> {
        observeFulfilled(handler)
        return self
    }
    
    private func observeFulfilled(_ handler: @escaping (Value) -> Void) {
        lock.lock()
        switch state {
        case .pending:
            successHandlers.append(handler)
            lock.unlock()
        case .fulfilled(let value):
            lock.unlock()
            if Thread.isMainThread {
                handler(value)
            } else {
                DispatchQueue.main.async { handler(value) }
            }
        case .rejected:
            lock.unlock()
        }
    }
    
    private func observeRejected(_ handler: @escaping (Error) -> Void) {
        lock.lock()
        switch state {
        case .pending:
            failureHandlers.append(handler)
            lock.unlock()
        case .fulfilled:
            lock.unlock()
        case .rejected(let error):
            lock.unlock()
            if Thread.isMainThread {
                handler(error)
            } else {
                DispatchQueue.main.async { handler(error) }
            }
        }
    }
}

extension Promise {

    static func from(_ work: @escaping () async throws -> Value) -> Promise<Value> {
        let promise = Promise<Value>()
        Task {
            do {
                let value = try await work()
                promise.resolve(value)  // ← strong reference, не weak
            } catch {
                promise.reject(error)
            }
        }
        return promise
    }
    
    func await() async throws -> Value {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Value, Error>) in
            // Atomic guard против двойного resume
            let resumed = ResumeGuard()
            
            self.sink { value in
                guard resumed.tryConsume() else { return }
                continuation.resume(returning: value)
            }
            self.catch { error in
                guard resumed.tryConsume() else { return }
                continuation.resume(throwing: error)
            }
        }
    }
}

private final class ResumeGuard {
    private var consumed = false
    private let lock = NSLock()
    
    func tryConsume() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !consumed else { return false }
        consumed = true
        return true
    }
}

extension Promise {
    static func resolved(_ value: Value) -> Promise<Value> {
        let p = Promise<Value>()
        p.resolve(value)
        return p
    }
    
    static func rejected(_ error: Error) -> Promise<Value> {
        let p = Promise<Value>()
        p.reject(error)
        return p
    }
}
