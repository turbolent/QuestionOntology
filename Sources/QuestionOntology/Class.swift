import ParserDescription


public final class Class<M>: HasEquivalents where M: OntologyMappings {

    public let identifier: String
    private unowned var ontology: QuestionOntology<M>

    public private(set) var superClassIdentifiers: Set<String> = []
    public var equivalents: Set<Equivalent<M>> = []
    public var patterns: [ClassPattern] = []

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
    public func isSubClass(of superClasses: Class...) -> Class {
        superClassIdentifiers.formUnion(superClasses.map { $0.identifier })
        return self
    }

    @discardableResult
    public func hasPattern(_ pattern: ClassPattern) -> Class {
        patterns.append(pattern)
        return self
    }

    @discardableResult
    public func hasPatterns(_ patterns: ClassPattern...) -> Class {
        patterns.forEach { hasPattern($0) }
        return self
    }
}


extension Class: Equatable {

    public static func == (lhs: Class, rhs: Class) -> Bool {
        return lhs.identifier == rhs.identifier
            && lhs.equivalents == rhs.equivalents
            && lhs.superClassIdentifiers == rhs.superClassIdentifiers
            && lhs.patterns == rhs.patterns
    }
}


extension Class: CustomStringConvertible {
    public var description: String {
        return "Class(\(String(reflecting: identifier)))"
    }
}


extension Class: Codable {

    internal enum CodingKeys: String, CodingKey {
        case identifier
        case equivalents
        case superClasses = "superclasses"
        case patterns
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)

        if !equivalents.isEmpty {
            try container.encode(
                equivalents.sorted(),
                forKey: .equivalents
            )
        }

        if !superClassIdentifiers.isEmpty {
            try container.encode(
                superClassIdentifiers.sorted(),
                forKey: .superClasses
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

        if let equivalents =
            try container.decodeIfPresent(Set<Equivalent<M>>.self, forKey: .equivalents)
        {
            self.equivalents = equivalents
        }

        if let superClassIdentifiers =
            try container.decodeIfPresent(Set<String>.self, forKey: .superClasses)
        {
            self.superClassIdentifiers = superClassIdentifiers
            for identifier in superClassIdentifiers {
                codingUserInfo.reference(class: identifier)
            }
        }

        if let patterns =
            try container.decodeIfPresent([ClassPattern].self, forKey: .patterns)
        {
            self.patterns = patterns
        }
    }
}
