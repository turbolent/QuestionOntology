

public indirect enum Equivalent<M>: Hashable where M: OntologyMappings {

    public struct Segment: Hashable {

        public enum Identifier: Hashable {
            case incoming(String)
            case outgoing(String)
            case individual(String)
        }

        fileprivate let identifier: Identifier

        public static func incoming(_ property: Property<M>) -> Segment {
            return Segment(identifier: .incoming(property.identifier))
        }

        public static func outgoing(_ property: Property<M>) -> Segment {
            return Segment(identifier: .outgoing(property.identifier))
        }

        public static func individual(_ individual: Individual<M>) -> Segment {
            return Segment(identifier: .individual(individual.identifier))
        }
    }

    case segments([Segment])
    case and([Equivalent])
}


extension Equivalent: Codable {

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case segments
        case and
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .segments(let segments):
            try container.encode(segments, forKey: .segments)

        case .and(let equivalents):
            try container.encode(equivalents, forKey: .and)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        for codingKey in CodingKeys.allCases {
            switch codingKey {
            case .segments:
                if let segments =
                    try container.decodeIfPresent([Segment].self, forKey: .segments)
                {
                    self = .segments(segments)
                    return
                }

            case .and:
                if let equivalents =
                    try container.decodeIfPresent([Equivalent<M>].self, forKey: .and)
                {
                    self = .and(equivalents)
                    return
                }
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}


extension Equivalent.Segment: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(identifier)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        identifier = try container.decode(Identifier.self)
    }
}


extension Equivalent.Segment.Identifier: Codable {

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case incoming
        case outgoing
        case individual
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .incoming(let identifier):
            try container.encode(identifier, forKey: .incoming)

        case .outgoing(let identifier):
            try container.encode(identifier, forKey: .outgoing)

        case .individual(let identifier):
            try container.encode(identifier, forKey: .individual)
        }
    }

    public init(from decoder: Decoder) throws {
        let codingUserInfo =
            try QuestionOntology<M>.codingUserInfo(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)

        for codingKey in CodingKeys.allCases {
            switch codingKey {
            case .incoming:
                if let identifier =
                    try container.decodeIfPresent(String.self, forKey: .incoming)
                {
                    self = .incoming(identifier)
                    codingUserInfo.reference(property: identifier)
                    return
                }
            case .outgoing:
                if let identifier =
                    try container.decodeIfPresent(String.self, forKey: .outgoing)
                {
                    self = .outgoing(identifier)
                    codingUserInfo.reference(property: identifier)
                    return
                }
            case .individual:
                if let identifier =
                    try container.decodeIfPresent(String.self, forKey: .individual)
                {
                    self = .individual(identifier)
                    codingUserInfo.reference(individual: identifier)
                    return
                }
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}


extension Equivalent: Comparable {

    private var orderIndex: Int {
        switch self {
        case .segments:
            return 0
        case .and:
            return 2
        }
    }

    public static func < (lhs: Equivalent, rhs: Equivalent) -> Bool {
        switch (lhs, rhs) {
        case let (.segments(left), .segments(right)):
            for (leftSegment, rightSegment) in zip(left, right) {
                if leftSegment < rightSegment {
                    return true
                }
                if leftSegment > rightSegment {
                    return false
                }
            }
            return left.count < right.count

        case let (.and(left), .and(right)):

            for (leftEquivalent, rightEquivalent) in zip(left, right) {
                if leftEquivalent < rightEquivalent {
                    return true
                }
                if leftEquivalent > rightEquivalent {
                    return false
                }
            }
            return left.count < right.count

        case (.segments, _), (.and, _):
            return lhs.orderIndex < rhs.orderIndex
        }
    }
}


extension Equivalent.Segment: Comparable {
    public static func < (
        lhs: Equivalent.Segment,
        rhs: Equivalent.Segment
    ) -> Bool {
        return lhs.identifier < rhs.identifier
    }
}


extension Equivalent.Segment.Identifier: Comparable {

    private var orderIndex: Int {
        switch self {
        case .incoming:
            return 0
        case .outgoing:
            return 1
        case .individual:
            return 2
        }
    }

    public static func < (
        lhs: Equivalent.Segment.Identifier,
        rhs: Equivalent.Segment.Identifier
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.incoming(left), .incoming(right)):
            return left < right
        case let (.outgoing(left), .outgoing(right)):
            return left < right
        case let (.individual(left), .individual(right)):
            return left < right
        case (.incoming, _), (.outgoing, _), (.individual, _):
            return lhs.orderIndex < rhs.orderIndex
        }
    }
}
