
public final class Individual<M> where M: OntologyMappings {

    public let identifier: String
    public fileprivate(set) var typeIdentifiers: Set<String> = []

    internal init(identifier: String) {
        self.identifier = identifier
    }
}


extension Individual: Equatable {

    public static func == (lhs: Individual, rhs: Individual) -> Bool {
        return lhs.identifier == rhs.identifier
            && lhs.typeIdentifiers == rhs.typeIdentifiers
    }
}


extension Individual: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(typeIdentifiers )
    }
}


extension Individual: CustomStringConvertible {
    public var description: String {
        return "Individual(\(String(reflecting: identifier)))"
    }
}


extension Individual: Codable {

    internal enum CodingKeys: CodingKey {
        case identifier
        case types
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        if !typeIdentifiers.isEmpty {
            try container.encode(typeIdentifiers, forKey: .types)
        }
    }

    public convenience init(from decoder: Decoder) throws {
        let codingUserInfo =
            try QuestionOntology<M>.codingUserInfo(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(String.self, forKey: .identifier)
        self.init(identifier: identifier)

        if let typeIdentifiers =
            try container.decodeIfPresent(Set<String>.self, forKey: .types)
        {
            self.typeIdentifiers = typeIdentifiers
            for identifier in typeIdentifiers {
                codingUserInfo.reference(class: identifier)
            }
        }
    }
}


public protocol HasIndividualIdentifier {
    var individualIdentifier: String { get }
}


extension Individual: HasIndividualIdentifier {

    public var individualIdentifier: String {
        return identifier
    }
}


extension IndividualBuilder: HasIndividualIdentifier {

    public var individualIdentifier: String {
        return individual.identifier
    }
}


public final class IndividualBuilder<Mappings>
    where Mappings: OntologyMappings
{

    public private(set) unowned var ontology: QuestionOntology<Mappings>
    public private(set) unowned var individual: Individual<Mappings>

    internal init(ontology: QuestionOntology<Mappings>, individual: Individual<Mappings>) {
        self.ontology = ontology
        self.individual = individual
    }

    @discardableResult
    public func map(to mapped: Mappings.Individual) -> Self {
        ontology.map(individual, to: mapped)
        return self
    }

    @discardableResult
    public func isA(_ types: HasClassIdentifier...) -> Self {
        individual.typeIdentifiers.formUnion(types.map { $0.classIdentifier })
        return self
    }
}
