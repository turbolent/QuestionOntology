import ParserDescription

public enum PropertyPattern: Hashable {
    case _named(AnyPattern)
    case _inverse(AnyPattern)
    case _value(AnyPattern)
    case _adjective(lemma: String)
    case _superlativeAdjective(lemma: String, order: Order)
    case _comparative(AnyPattern, Comparison)

    public static func named<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._named(AnyPattern(pattern))
    }

    public static func inverse<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._inverse(AnyPattern(pattern))
    }

    public static func value<T: Pattern>(_ pattern: T) -> PropertyPattern {
        return ._value(AnyPattern(pattern))
    }

    public static func adjective(lemma: String) -> PropertyPattern {
        return ._adjective(lemma: lemma)
    }

    public static func superlativeAdjective(lemma: String, order: Order) -> PropertyPattern {
        return ._superlativeAdjective(lemma: lemma, order: order)
    }

    public static func comparative<T: Pattern>(
        _ pattern: T,
        _ comparison: Comparison
    )
        -> PropertyPattern
    {
        return ._comparative(AnyPattern(pattern), comparison)
    }

    public var hasDefinedLength: Bool {
        switch self {
        case ._named(let pattern),
             ._inverse(let pattern),
             ._value(let pattern),
             ._comparative(let pattern, _):
            return pattern.hasDefinedLength

        case ._adjective,
             ._superlativeAdjective:
            return true
        }
    }
}

extension PropertyPattern: Codable {

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case named
        case inverse
        case value
        case adjective
        case superlativeAdjective = "superlative_adjective"
        case comparative
        case comparison
        case order
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case ._named(let pattern):
            try container.encode(pattern, forKey: .named)

        case ._inverse(let pattern):
            try container.encode(pattern, forKey: .inverse)

        case ._value(let pattern):
            try container.encode(pattern, forKey: .value)

        case ._adjective(let pattern):
            try container.encode(pattern, forKey: .adjective)

        case let ._superlativeAdjective(pattern, order):
            try container.encode(pattern, forKey: .superlativeAdjective)
            try container.encode(order, forKey: .order)

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

            case .inverse:
                if let pattern =
                    try container.decodeIfPresent(AnyPattern.self, forKey: .inverse)
                {
                    self = ._inverse(pattern)
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
                if let lemma =
                    try container.decodeIfPresent(String.self, forKey: .adjective)
                {
                    self = ._adjective(lemma: lemma)
                    return
                }

            case .superlativeAdjective:
                if let lemma =
                    try container.decodeIfPresent(String.self, forKey: .superlativeAdjective)
                {
                    let order =
                        try container.decode(Order.self, forKey: .order)
                    self = ._superlativeAdjective(lemma: lemma, order: order)
                    return
                }

            case .comparative:
                if let pattern =
                    try container.decodeIfPresent(AnyPattern.self, forKey: .comparative)
                {
                    let comparison =
                        try container.decode(Comparison.self, forKey: .comparison)
                    self = ._comparative(pattern, comparison)
                    return
                }

            case .comparison, .order:
                break
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}
