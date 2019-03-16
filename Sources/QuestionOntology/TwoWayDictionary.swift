
public struct TwoWayDictionary<Left, Right>: Hashable
    where Left: Hashable, Right: Hashable
{
    public private(set) var leftToRight: [Left: Right] = [:]
    public private(set) var rightToLeft: [Right: Left] = [:]

    public internal(set) subscript(left: Left) -> Right? {
        get {
            return leftToRight[left]
        }
        set {
            if let right = newValue {
                set(left: left, right: right)
            } else if let right = leftToRight[left] {
                leftToRight[left] = nil
                rightToLeft[right] = nil
            }
        }
    }

    public internal(set) subscript(right: Right) -> Left? {
        get {
            return rightToLeft[right]
        }
        set {
            if let left = newValue {
                set(left: left, right: right)
            } else if let left = rightToLeft[right] {
                rightToLeft[right] = nil
                leftToRight[left] = nil
            }
        }
    }

    private mutating func set(left: Left, right: Right) {
        leftToRight[left] = right
        rightToLeft[right] = left
    }

    public var isEmpty: Bool {
        return leftToRight.isEmpty
    }
}


extension TwoWayDictionary: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Left, Right)...) {
        for (left, right) in elements {
            set(left: left, right: right)
        }
    }
}


extension TwoWayDictionary: Codable where Left: Codable, Right: Codable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(leftToRight)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        leftToRight = try container.decode([Left: Right].self)
        for (left, right) in leftToRight {
            rightToLeft[right] = left
        }
    }
}
