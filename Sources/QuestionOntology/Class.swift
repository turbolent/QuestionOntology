
import ParserDescription


public final class Class<M> where M: OntologyMappings {

    public struct Equivalency: Hashable {

        public enum Segment: Hashable {
            case incoming(String)
            case outgoing(String)
            case individual(String)
        }

        public let segments: [Segment]

        init(_ segments: Segment...) {
            self.segments = segments
        }
    }


    public let identifier: String
    private unowned var ontology: QuestionOntology<M>

    public private(set) var superClassIdentifiers: Set<String> = []
    public private(set) var equivalencies: Set<Equivalency> = []
    public private(set) var pattern: Pattern?

    public var superClasses: [Class<M>] {
        return superClassIdentifiers.map {
            ontology.classes[$0]!
        }
    }

    public init(identifier: String, ontology: QuestionOntology<M>) {
        self.identifier = identifier
        self.ontology = ontology
    }

    @discardableResult
    public func map(to mapped: M.Class) -> Class {
        ontology.map(self, to: mapped)
        return self
    }

    @discardableResult
    public func isSubClassOf(_ superClasses: Class...) -> Class {
        superClassIdentifiers.formUnion(superClasses.map { $0.identifier })
        return self
    }

    @discardableResult
    public func hasEquivalent(outgoing: Property<M>, _ individual: Individual<M>) -> Class {
        equivalencies.insert(Equivalency(
            .outgoing(outgoing.identifier),
            .individual(individual.identifier)
        ))
        return self
    }

    @discardableResult
    public func hasEquivalent(outgoing: Property<M>) -> Class {
        equivalencies.insert(Equivalency(
            .outgoing(outgoing.identifier)
        ))
        return self
    }

    @discardableResult
    public func hasEquivalent(
        outgoing: Property<M>,
        outgoing secondOutgoing: Property<M>
    ) -> Class {

        equivalencies.insert(Equivalency(
            .outgoing(outgoing.identifier),
            .outgoing(secondOutgoing.identifier)
        ))
        return self
    }

    @discardableResult
    public func hasEquivalent(outgoing: Property<M>, incoming: Property<M>) -> Class {
        equivalencies.insert(Equivalency(
            .outgoing(outgoing.identifier),
            .incoming(incoming.identifier)
        ))
        return self
    }

    @discardableResult
    public func hasEquivalent(individual: Individual<M>, incoming: Property<M>) -> Class {
        equivalencies.insert(Equivalency(
            .individual(individual.identifier),
            .incoming(incoming.identifier)
        ))
        return self
    }

    @discardableResult
    public func hasEquivalent(incoming: Property<M>) -> Class {
        equivalencies.insert(Equivalency(
            .incoming(incoming.identifier)
        ))
        return self
    }

    @discardableResult
    public func hasEquivalent(
        incoming: Property<M>,
        incoming secondIncoming: Property<M>
    ) -> Class {

        equivalencies.insert(Equivalency(
            .incoming(incoming.identifier),
            .incoming(secondIncoming.identifier)
        ))
        return self
    }

    @discardableResult
    public func hasEquivalent(incoming: Property<M>, outgoing: Property<M>) -> Class {
        equivalencies.insert(Equivalency(
            .incoming(incoming.identifier),
            .outgoing(outgoing.identifier)
        ))
        return self
    }

    @discardableResult
    public func hasPattern(_ pattern: Pattern) -> Class {
        if let existingPattern = self.pattern {
            self.pattern = existingPattern.or(pattern)
        } else {
            self.pattern = pattern
        }
        return self
    }

    @discardableResult
    public func hasPatterns(_ pattern: Pattern, _ morePatterns: Pattern...) -> Class {
        return hasPattern(morePatterns.reduce(pattern) { $0.or($1) })
    }
}


extension Class: Equatable {

    public static func == (lhs: Class, rhs: Class) -> Bool {
        // NOTE: not comparing patterns
        return lhs.identifier == rhs.identifier
            && lhs.equivalencies == rhs.equivalencies
            && lhs.superClassIdentifiers == rhs.superClassIdentifiers
    }
}


extension Class: CustomStringConvertible {
    public var description: String {
        return "Class(\(String(reflecting: identifier)))"
    }
}


extension Class.Equivalency.Segment: Comparable {

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
        lhs: Class.Equivalency.Segment,
        rhs: Class.Equivalency.Segment
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


extension Class.Equivalency: Comparable {

    public static func < (lhs: Class.Equivalency, rhs: Class.Equivalency) -> Bool {
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




extension Class: Codable {

    internal enum CodingKeys: String, CodingKey {
        case identifier
        case equivalencies
        case superClasses = "superclasses"
        case pattern
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)

        if !equivalencies.isEmpty {
            try container.encode(
                equivalencies.sorted(),
                forKey: .equivalencies
            )
        }

        if !superClassIdentifiers.isEmpty {
            try container.encode(
                superClassIdentifiers.sorted(),
                forKey: .superClasses
            )
        }

        if let pattern = pattern {
            try container.encode(TypedPattern(pattern), forKey: .pattern)
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

        if let equivalencies =
            try container.decodeIfPresent(Set<Equivalency>.self, forKey: .equivalencies)
        {
            self.equivalencies = equivalencies
        }

        if let superClassIdentifiers =
            try container.decodeIfPresent(Set<String>.self, forKey: .superClasses)
        {
            self.superClassIdentifiers = superClassIdentifiers
            for identifier in superClassIdentifiers {
                codingUserInfo.reference(class: identifier)
            }
        }

        if let typedPattern =
            try container.decodeIfPresent(TypedPattern.self, forKey: .pattern)
        {
            pattern = typedPattern.pattern
        }
    }
}


extension Class.Equivalency: Codable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: segments)
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var segments: [Class.Equivalency.Segment] = []
        while !container.isAtEnd {
            segments.append(try container.decode(Segment.self))
        }
        self.segments = segments
    }
}


extension Class.Equivalency.Segment: Codable {

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
