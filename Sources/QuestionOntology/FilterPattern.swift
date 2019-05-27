import ParserDescription


public enum FilterPattern: Hashable {
    case _named(AnyPattern)
    case _comparative(AnyPattern, Comparison)

    public static func named<T>(_ pattern: T) -> FilterPattern
        where T: Pattern
    {
        return ._named(AnyPattern(pattern))
    }

    public static func comparative<T>(_ pattern: T, comparison: Comparison) -> FilterPattern
        where T: Pattern
    {
        return ._comparative(AnyPattern(pattern), comparison)
    }

    public var pattern: AnyPattern {
        switch self {
        case let ._comparative(pattern, _),
             let ._named(pattern):
            return pattern
        }
    }

    public var hasDefinedLength: Bool {
        return pattern.hasDefinedLength
    }
}


extension FilterPattern: Codable {

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case named
        case comparative
        case comparison
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case ._named(let pattern):
            try container.encode(pattern, forKey: .named)

        case let ._comparative(pattern, comparison):
            try container.encode(pattern, forKey: .comparative)
            try container.encode(comparison, forKey: .comparison)
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

            case .comparative:
                if let pattern =
                    try container.decodeIfPresent(AnyPattern.self, forKey: .comparative)
                {
                    let comparison = try container.decode(Comparison.self, forKey: .comparison)
                    self = ._comparative(pattern, comparison)
                    return
                }

            // ignore secondary coding keys (not used for type dispatch, only for additional info)
            case .comparison:
                break
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}
