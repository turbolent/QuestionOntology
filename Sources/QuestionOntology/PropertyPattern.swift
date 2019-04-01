import ParserDescription

public enum PropertyPattern: Hashable {
    case _named(AnyPattern)
    case _adjective(AnyPattern)

    public static func named<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._named(AnyPattern(pattern))
    }

    public static func adjective<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._adjective(AnyPattern(pattern))
    }
}

extension PropertyPattern: Codable {

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case named
        case adjective
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case ._named(let pattern):
            try container.encode(pattern, forKey: .named)
        case ._adjective(let pattern):
            try container.encode(pattern, forKey: .adjective)
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
            case .adjective:
                if let pattern =
                    try container.decodeIfPresent(AnyPattern.self, forKey: .adjective)
                {
                    self = ._adjective(pattern)
                    return
                }
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}
