import ParserDescription

public enum ClassPattern: Hashable {
    case _named(AnyPattern)

    public static func named<T: Pattern>(_ pattern: T) -> ClassPattern {
        return ._named(AnyPattern(pattern))
    }
}


extension ClassPattern: Codable {

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case named
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case ._named(let pattern):
            try container.encode(pattern, forKey: .named)
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
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}
