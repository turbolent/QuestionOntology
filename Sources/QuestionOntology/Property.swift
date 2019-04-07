import ParserDescription


public final class Property<M>: HasEquivalents where M: OntologyMappings {

    public let identifier: String
    private unowned var ontology: QuestionOntology<M>

    public private(set) var superPropertyIdentifiers: Set<String> = []
    public var equivalents: Set<Equivalent<M>> = []
    public var patterns: [PropertyPattern] = []

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
    public func makeSymmetric() -> Property {
        isSymmetric = true
        return self
    }

    @discardableResult
    public func makeTransitive() -> Property {
        isTransitive = true
        return self
    }

    @discardableResult
    public func hasPattern(_ pattern: PropertyPattern) -> Property {
        patterns.append(pattern)
        return self
    }

    @discardableResult
    public func hasPatterns(_ patterns: PropertyPattern...) -> Property {
        patterns.forEach { hasPattern($0) }
        return self
    }
}


extension Property: Equatable {

    public static func == (lhs: Property, rhs: Property) -> Bool {
        return lhs.identifier == rhs.identifier
            && lhs.isSymmetric == rhs.isSymmetric
            && lhs.isTransitive == rhs.isTransitive
            && lhs.equivalents == rhs.equivalents
            && lhs.superPropertyIdentifiers == rhs.superPropertyIdentifiers
            && lhs.patterns == rhs.patterns
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
        case equivalents
        case superProperties = "superproperties"
        case patterns
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

        if !equivalents.isEmpty {
            try container.encode(
                equivalents.sorted(),
                forKey: .equivalents
            )
        }

        if !superPropertyIdentifiers.isEmpty {
            try container.encode(
                superPropertyIdentifiers.sorted(),
                forKey: .superProperties
            )
        }

        if !patterns.isEmpty {
            try container.encode(patterns, forKey: .patterns)
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

        if let equivalents =
            try container.decodeIfPresent(Set<Equivalent<M>>.self, forKey: .equivalents)
        {
            self.equivalents = equivalents
        }

        if let superPropertyIdentifiers =
            try container.decodeIfPresent(Set<String>.self, forKey: .superProperties)
        {
            self.superPropertyIdentifiers = superPropertyIdentifiers
            for identifier in superPropertyIdentifiers {
                codingUserInfo.reference(property: identifier)
            }
        }

        if let patterns =
            try container.decodeIfPresent([PropertyPattern].self, forKey: .patterns)
        {
            self.patterns = patterns
        }
    }
}
