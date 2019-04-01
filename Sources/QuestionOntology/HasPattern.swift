import ParserDescription

public protocol HasPattern: class {
    var pattern: AnyPattern? { get set }
}


public extension HasPattern {

    @discardableResult
    func hasPattern(_ pattern: AnyPattern) -> Self {
        if let existingPattern = self.pattern {
            self.pattern = AnyPattern(existingPattern.or(pattern))
        } else {
            self.pattern = pattern
        }
        return self
    }

    @discardableResult
    func hasPattern<T: Pattern>(_ pattern: T) -> Self {
        return hasPattern(AnyPattern(pattern))
    }

    @discardableResult
    func hasPatterns(_ pattern: AnyPattern, _ morePatterns: AnyPattern...) -> Self {
        return hasPattern(morePatterns.reduce(pattern) { AnyPattern($0.or($1)) })
    }

    @discardableResult
    func hasPatterns<T: Pattern>(_ pattern: T, _ morePatterns: T...) -> Self {
        return hasPattern(morePatterns.reduce(AnyPattern(pattern)) { AnyPattern($0.or($1)) })
    }
}
