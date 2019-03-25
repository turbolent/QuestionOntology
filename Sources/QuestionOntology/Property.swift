
import ParserDescription


public final class Property<M> where M: OntologyMappings {

    public struct Equivalency: Hashable {

        public enum Segment: Hashable {
            case incoming(String)
            case outgoing(String)
        }

        public let segments: [Segment]

        init(_ segments: Segment...) {
            self.segments = segments
        }
    }

    public let identifier: String
    private unowned var ontology: QuestionOntology<M>

    public private(set) var superPropertyIdentifiers: Set<String> = []
    public private(set) var equivalencies: Set<Equivalency> = []

    public var isSymmetric = false
    public var isTransitive = false

    public var superProperties: [Property<M>] {
        return superPropertyIdentifiers.map {
            ontology.properties[$0]!
        }
    }

    public init(identifier: String, ontology: QuestionOntology<M>) {
        self.identifier = identifier
        self.ontology = ontology
    }

    @discardableResult
    public func map(to mapped: M.Property) -> Property {
        ontology.map(self, to: mapped)
        return self
    }

    @discardableResult
    public func isSubProperty(of superProperties: Property...) -> Property {
        superPropertyIdentifiers.formUnion(superProperties.map { $0.identifier })
        return self
    }

    @discardableResult
    public func hasEquivalent(outgoing: Property) -> Property {
        equivalencies.insert(Equivalency(
            .outgoing(outgoing.identifier)
        ))
        return self
    }

    @discardableResult
    public func hasEquivalent(incoming: Property) -> Property {
        equivalencies.insert(Equivalency(
            .incoming(incoming.identifier)
        ))
        return self
    }

    @discardableResult
    public func makeSymmetric() -> Property {
        isSymmetric = true
        return self
    }

    @discardableResult
    public func makeTransitive() -> Property {
        isTransitive = true
        return self
    }
}


extension Property: Equatable {

    public static func == (lhs: Property, rhs: Property) -> Bool {
        return lhs.identifier == rhs.identifier
            && lhs.isSymmetric == rhs.isSymmetric
            && lhs.isTransitive == rhs.isTransitive
            && lhs.equivalencies == rhs.equivalencies
            && lhs.superPropertyIdentifiers == rhs.superPropertyIdentifiers
    }
}


extension Property: CustomStringConvertible {
    public var description: String {
        return "Property(\(String(reflecting: identifier)))"
    }
}


extension Property: Codable {

    internal enum CodingKeys: String, CodingKey {
        case identifier
        case symmetric
        case transitive
        case equivalencies
        case superProperties = "superproperties"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        if isSymmetric {
            try container.encode(true, forKey: .symmetric)
        }
        if isTransitive {
            try container.encode(true, forKey: .transitive)
        }
        if !equivalencies.isEmpty {
            try container.encode(
                equivalencies.sorted(),
                forKey: .equivalencies
            )
        }
        if !superPropertyIdentifiers.isEmpty {
            try container.encode(
                superPropertyIdentifiers.sorted(),
                forKey: .superProperties
            )
        }
    }

    public convenience init(from decoder: Decoder) throws {
        let codingUserInfo =
            try QuestionOntology<M>.codingUserInfo(from: decoder)

        guard let ontology = codingUserInfo.ontology else {
            throw QuestionOntologyDecodingError.notPrepared
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(String.self, forKey: .identifier)
        self.init(identifier: identifier, ontology: ontology)

        if let isSymmetric = try container.decodeIfPresent(Bool.self, forKey: .symmetric) {
            self.isSymmetric = isSymmetric
        }

        if let isTransitive = try container.decodeIfPresent(Bool.self, forKey: .transitive) {
            self.isTransitive = isTransitive
        }

        if let equivalencies =
            try container.decodeIfPresent(Set<Equivalency>.self, forKey: .equivalencies)
        {
            self.equivalencies = equivalencies
        }

        if let superPropertyIdentifiers =
            try container.decodeIfPresent(Set<String>.self, forKey: .superProperties)
        {
            self.superPropertyIdentifiers = superPropertyIdentifiers
            for identifier in superPropertyIdentifiers {
                codingUserInfo.reference(property: identifier)
            }
        }
    }
}


extension Property.Equivalency: Comparable {

    public static func < (lhs: Property.Equivalency, rhs: Property.Equivalency) -> Bool {
        for (leftSegment, rightSegment) in zip(lhs.segments, rhs.segments) {
            if leftSegment < rightSegment {
                return true
            }
            if leftSegment > rightSegment {
                return false
            }
        }
        return lhs.segments.count < rhs.segments.count
    }
}


extension Property.Equivalency: Codable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: segments)
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var segments: [Property.Equivalency.Segment] = []
        while !container.isAtEnd {
            segments.append(try container.decode(Segment.self))
        }
        self.segments = segments
    }
}


extension Property.Equivalency.Segment: Comparable {

    private var orderIndex: Int {
        switch self {
        case .incoming:
            return 0
        case .outgoing:
            return 1
        }
    }

    public static func < (
        lhs: Property.Equivalency.Segment,
        rhs: Property.Equivalency.Segment
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.incoming(left), .incoming(right)):
            return left < right
        case let (.outgoing(left), .outgoing(right)):
            return left < right
        case (.incoming, _), (.outgoing, _):
            return lhs.orderIndex < rhs.orderIndex
        }
    }
}


extension Property.Equivalency.Segment: Codable {

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case incoming
        case outgoing
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .incoming(let identifier):
            try container.encode(identifier, forKey: .incoming)

        case .outgoing(let identifier):
            try container.encode(identifier, forKey: .outgoing)
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
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}
