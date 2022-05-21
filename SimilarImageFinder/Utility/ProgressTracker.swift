//

import Foundation
import Combine

class ProgressTracker: ObservableObject {
    
    let progressSubject = PassthroughSubject<Void, Error>()
    
    @Published private(set) var total: Double = 0
    @Published private(set) var current: Double = 0
    @Published private(set) var percent: Double = 0
        
    public func setTotal(_ value: Double) {
        DispatchQueue.main.async {
            self.total = value
            self.progressSubject.send()
            self.current = 0
        }
    }
    
    public func update(_ value: Int) {
        self.update(Double(value))
    }
    
    /// Updates the current progress with a given value. New value = old value + given value.
    public func update(_ value: Double) {
        DispatchQueue.main.async {
            self.current = self.current + value
            
            if self.total == 0 {
                self.percent = 0
            } else {
                self.percent = self.current / self.total
            }
                        
            self.progressSubject.send()
        }
    }
    
    public func setCurrent(_ value: Int) {
        self.setCurrent(Double(value))
    }
    
    public func setCurrent(_ value: Double) {
        DispatchQueue.main.async {
            self.current = value
            
            if self.total == 0 {
                self.percent = 0
            } else {
                self.percent = self.current / self.total
            }
            
            self.progressSubject.send()
        }
    }
    
    public func complete() {
        progressSubject.send(completion: .finished)
    }
    
    public func whenChanged() -> AnyPublisher<Void, Error> {
        return progressSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
}
