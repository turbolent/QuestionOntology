import ParserDescription


public final class Property<Mappings>
    where Mappings: OntologyMappings
{
    public let identifier: String

    public fileprivate(set) var superPropertyIdentifiers: Set<String> = []
    public var equivalents: Set<Equivalent<Mappings>> = []
    public var patterns: [PropertyPattern] = []

    public var isSymmetric = false
    public var isTransitive = false

    internal init(identifier: String) {
        self.identifier = identifier
    }
}


extension Property: Equatable {

    public static func == (lhs: Property, rhs: Property) -> Bool {
        return lhs.identifier == rhs.identifier
            && lhs.superPropertyIdentifiers == rhs.superPropertyIdentifiers
            && lhs.equivalents == rhs.equivalents
            && lhs.patterns == rhs.patterns
            && lhs.isSymmetric == rhs.isSymmetric
            && lhs.isTransitive == rhs.isTransitive
    }
}


extension Property: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(superPropertyIdentifiers)
        hasher.combine(equivalents)
        hasher.combine(patterns)
        hasher.combine(isSymmetric)
        hasher.combine(isTransitive)
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
            try QuestionOntology<Mappings>.codingUserInfo(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(String.self, forKey: .identifier)
        self.init(identifier: identifier)

        if let isSymmetric = try container.decodeIfPresent(Bool.self, forKey: .symmetric) {
            self.isSymmetric = isSymmetric
        }

        if let isTransitive = try container.decodeIfPresent(Bool.self, forKey: .transitive) {
            self.isTransitive = isTransitive
        }

        if let equivalents =
            try container.decodeIfPresent(Set<Equivalent<Mappings>>.self, forKey: .equivalents)
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


public protocol HasPropertyIdentifier {
    var propertyIdentifier: String { get }
}


extension Property: HasPropertyIdentifier {
    public var propertyIdentifier: String {
        return identifier
    }
}


extension PropertyBuilder: HasPropertyIdentifier {
    public var propertyIdentifier: String {
        return property.identifier
    }
}


public final class PropertyBuilder<Mappings>: HasEquivalents
    where Mappings: OntologyMappings
{
    public private(set) unowned var ontology: QuestionOntology<Mappings>
    public private(set) unowned var property: Property<Mappings>

    internal init(ontology: QuestionOntology<Mappings>, property: Property<Mappings>) {
        self.ontology = ontology
        self.property = property
    }

    @discardableResult
    public func map(to mapped: Mappings.Property) -> Self {
        ontology.map(property, to: mapped)
        return self
    }

    @discardableResult
    public func isSubProperty(of superProperties: HasPropertyIdentifier...) -> Self {
        property.superPropertyIdentifiers
            .formUnion(superProperties.map { $0.propertyIdentifier })
        return self
    }

    @discardableResult
    public func makeSymmetric() -> Self {
        property.isSymmetric = true
        return self
    }

    @discardableResult
    public func makeTransitive() -> Self {
        property.isTransitive = true
        return self
    }

    @discardableResult
    public func hasPattern(_ pattern: PropertyPattern) -> Self {
        guard pattern.hasDefinedLength else {
            fatalError("invalid property pattern, unknown length: \(pattern)")
        }
        property.patterns.append(pattern)
        return self
    }

    @discardableResult
    public func hasPatterns(_ patterns: PropertyPattern...) -> Self {
        patterns.forEach { hasPattern($0) }
        return self
    }

    @discardableResult
    public func hasEquivalent(_ equivalent: Equivalent<Mappings>) -> Self {
        property.equivalents.insert(equivalent)
        return self
    }
}
