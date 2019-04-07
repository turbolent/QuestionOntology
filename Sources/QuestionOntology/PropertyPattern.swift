import ParserDescription

public enum PropertyPattern: Hashable {
    case _named(AnyPattern)
    case _value(AnyPattern)
    case _adjective(AnyPattern)
    case _oppositeAdjective(AnyPattern)

    public static func named<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._named(AnyPattern(pattern))
    }

    public static func value<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._value(AnyPattern(pattern))
    }

    public static func adjective<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._adjective(AnyPattern(pattern))
    }

    public static func oppositeAdjective<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._oppositeAdjective(AnyPattern(pattern))
    }
}

extension PropertyPattern: Codable {

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case named
        case value
        case adjective
        case oppositeAdjective = "opposite_adjective"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case ._named(let pattern):
            try container.encode(pattern, forKey: .named)
        case ._value(let pattern):
            try container.encode(pattern, forKey: .value)
        case ._adjective(let pattern):
            try container.encode(pattern, forKey: .adjective)
        case ._oppositeAdjective(let pattern):
            try container.encode(pattern, forKey: .oppositeAdjective)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        for codingKey in CodingKeys.allCases {
            switch codingKey {
            case .named:
                if let pattern =
                    try container.decodeIfPresent(AnyPattern.self, forKey: .named)
                {
                    self = ._named(pattern)
                    return
                }
            case .value:
                if let pattern =
                    try container.decodeIfPresent(AnyPattern.self, forKey: .value)
                {
                    self = ._value(pattern)
                    return
                }
            case .adjective:
                if let pattern =
                    try container.decodeIfPresent(AnyPattern.self, forKey: .adjective)
                {
                    self = ._adjective(pattern)
                    return
                }
            case .oppositeAdjective:
                if let pattern =
                    try container.decodeIfPresent(AnyPattern.self, forKey: .oppositeAdjective)
                {
                    self = ._oppositeAdjective(pattern)
                    return
                }
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}
