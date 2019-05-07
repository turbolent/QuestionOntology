import ParserDescription


public final class Class<Mappings>
    where Mappings: OntologyMappings
{
    public let identifier: String

    public fileprivate(set) var superClassIdentifiers: Set<String> = []
    public var equivalents: Set<Equivalent<Mappings>> = []
    public var patterns: [ClassPattern] = []

    internal init(identifier: String) {
        self.identifier = identifier
    }
}


extension Class: Equatable {

    public static func == (lhs: Class, rhs: Class) -> Bool {
        return lhs.identifier == rhs.identifier
            && lhs.superClassIdentifiers == rhs.superClassIdentifiers
            && lhs.equivalents == rhs.equivalents
            && lhs.patterns == rhs.patterns
    }
}


extension Class: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(equivalents)
        hasher.combine(superClassIdentifiers)
        hasher.combine(patterns)
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
            try QuestionOntology<Mappings>.codingUserInfo(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let identifier = try container.decode(String.self, forKey: .identifier)
        self.init(identifier: identifier)

        if let equivalents =
            try container.decodeIfPresent(Set<Equivalent<Mappings>>.self, forKey: .equivalents)
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


public protocol HasClassIdentifier {
    var classIdentifier: String { get }
}


extension Class: HasClassIdentifier {
    public var classIdentifier: String {
        return identifier
    }
}


extension ClassBuilder: HasClassIdentifier {
    public var classIdentifier: String {
        return `class`.identifier
    }
}


public final class ClassBuilder<Mappings>: HasEquivalents
    where Mappings: OntologyMappings
{
    public private(set) unowned var ontology: QuestionOntology<Mappings>
    public private(set) unowned var `class`: Class<Mappings>

    internal init(ontology: QuestionOntology<Mappings>, class: Class<Mappings>) {
        self.ontology = ontology
        self.class = `class`
    }

    @discardableResult
    public func map(to mapped: Mappings.Class) -> Self {
        ontology.map(`class`, to: mapped)
        return self
    }

    @discardableResult
    public func isSubClass(of superClasses: HasClassIdentifier...) -> Self {
        `class`.superClassIdentifiers
            .formUnion(superClasses.map { $0.classIdentifier })
        return self
    }

    @discardableResult
    public func hasPattern(_ pattern: ClassPattern) -> Self {
        guard pattern.hasDefinedLength else {
            fatalError("invalid class pattern, unknown length: \(pattern)")
        }
        `class`.patterns.append(pattern)
        return self
    }

    @discardableResult
    public func hasPatterns(_ patterns: ClassPattern...) -> Self {
        patterns.forEach { hasPattern($0) }
        return self
    }

    @discardableResult
    public func hasEquivalent(_ equivalent: Equivalent<Mappings>) -> Self {
        `class`.equivalents.insert(equivalent)
        return self
    }
}
