import ParserDescription


public enum PropertyPattern: Hashable, Equatable {
    case _named(AnyPattern)
    case _value(AnyPattern, filter: FilterPattern?)
    case _inverse(AnyPattern, filter: FilterPattern?)
    case _adjective(lemma: String, filter: FilterPattern?)
    case _superlativeAdjective(lemma: String, order: Order)

    public static func named<T>(_ pattern: T) -> PropertyPattern
        where T: Pattern
    {
        return ._named(AnyPattern(pattern))
    }

    public static func inverse<T>(_ pattern: T, filter: FilterPattern? = nil) -> PropertyPattern
        where T: Pattern
    {
        return ._inverse(AnyPattern(pattern), filter: filter)
    }

    public static func value<T>(_ pattern: T, filter: FilterPattern? = nil) -> PropertyPattern
        where T: Pattern
    {
        return ._value(AnyPattern(pattern), filter: filter)
    }

    public static func adjective(lemma: String, filter: FilterPattern? = nil) -> PropertyPattern {
        return ._adjective(lemma: lemma, filter: filter)
    }

    public static func superlativeAdjective(lemma: String, order: Order) -> PropertyPattern {
        return ._superlativeAdjective(lemma: lemma, order: order)
    }

    public var hasDefinedLength: Bool {
        switch self {
        case let ._named(pattern):
            return pattern.hasDefinedLength

        case let ._value(pattern, filter),
             let ._inverse(pattern, filter):
            return pattern.hasDefinedLength
                && (filter?.hasDefinedLength ?? true)

        case let ._adjective(_, filter):
            return filter?.hasDefinedLength ?? true

        case ._superlativeAdjective:
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
        case order
        case filter
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let ._named(pattern):
            try container.encode(pattern, forKey: .named)

        case let ._inverse(pattern, filter):
            try container.encode(pattern, forKey: .inverse)
            try container.encodeIfPresent(filter, forKey: .filter)

        case let ._value(pattern, filter):
            try container.encode(pattern, forKey: .value)
            try container.encodeIfPresent(filter, forKey: .filter)

        case let ._adjective(lemma, filter):
            try container.encode(lemma, forKey: .adjective)
            try container.encodeIfPresent(filter, forKey: .filter)

        case let ._superlativeAdjective(pattern, order):
            try container.encode(pattern, forKey: .superlativeAdjective)
            try container.encode(order, forKey: .order)
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
                    let filter = try container.decodeIfPresent(FilterPattern.self, forKey: .filter)
                    self = ._inverse(pattern, filter: filter)
                    return
                }

            case .value:
                if let pattern =
                    try container.decodeIfPresent(AnyPattern.self, forKey: .value)
                {
                    let filter = try container.decodeIfPresent(FilterPattern.self, forKey: .filter)
                    self = ._value(pattern, filter: filter)
                    return
                }

            case .adjective:
                if let lemma =
                    try container.decodeIfPresent(String.self, forKey: .adjective)
                {
                    let filter = try container.decodeIfPresent(FilterPattern.self, forKey: .filter)
                    self = ._adjective(lemma: lemma, filter: filter)
                    return
                }

            case .superlativeAdjective:
                if let lemma =
                    try container.decodeIfPresent(String.self, forKey: .superlativeAdjective)
                {
                    let order = try container.decode(Order.self, forKey: .order)
                    self = ._superlativeAdjective(lemma: lemma, order: order)
                    return
                }

            // ignore secondary coding keys (not used for type dispatch, only for additional info)
            case .order, .filter:
                break
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}
