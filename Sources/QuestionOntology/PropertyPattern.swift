import ParserDescription

public enum PropertyPattern: Hashable {
    case _named(AnyPattern)
    case _adjective(AnyPattern)
    case _comparative(AnyPattern, filter: AnyPattern)

    public static func named<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._named(AnyPattern(pattern))
    }

    public static func adjective<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._adjective(AnyPattern(pattern))
    }

    public static func comparative<T, U>(_ pattern: T, filter: U) -> PropertyPattern
        where T: Pattern, U: Pattern
    {
        return ._comparative(
            AnyPattern(pattern),
            filter: AnyPattern(filter)
        )
    }
}

extension PropertyPattern: Codable {

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case named
        case adjective
        case comparative
        case filter
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case ._named(let pattern):
            try container.encode(pattern, forKey: .named)
        case ._adjective(let pattern):
            try container.encode(pattern, forKey: .adjective)
        case let ._comparative(pattern, filter):
            try container.encode(pattern, forKey: .comparative)
            try container.encode(filter, forKey: .filter)
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
            case .comparative:
                if
                    let pattern =
                        try container.decodeIfPresent(AnyPattern.self, forKey: .comparative),
                    let filter =
                        try container.decodeIfPresent(AnyPattern.self, forKey: .filter)
                {
                    self = ._comparative(pattern, filter: filter)
                    return
                }
            case .filter:
                continue
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}
