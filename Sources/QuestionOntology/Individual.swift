
public final class Individual<M> where M: OntologyMappings {

    public let identifier: String
    public private(set) unowned var ontology: QuestionOntology<M>

    public private(set) var typeIdentifiers: Set<String> = []

    public var types: [Class<M>] {
        return typeIdentifiers.map {
            ontology.classes[$0]!
        }
    }

    public init(identifier: String, ontology: QuestionOntology<M>) {
        self.identifier = identifier
        self.ontology = ontology
    }

    @discardableResult
    public func map(to mapped: M.Individual) -> Individual {
        ontology.map(self, to: mapped)
        return self
    }

    @discardableResult
    public func isA(_ types: Class<M>...) -> Individual {
        let typeIdentifiers = types.map { $0.identifier }
        self.typeIdentifiers.formUnion(typeIdentifiers)
        return self
    }
}


extension Individual: Equatable {

    public static func == (lhs: Individual, rhs: Individual) -> Bool {
        return lhs.identifier == rhs.identifier
            && lhs.typeIdentifiers == rhs.typeIdentifiers
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

        guard let ontology = codingUserInfo.ontology else {
            throw QuestionOntologyDecodingError.notPrepared
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(String.self, forKey: .identifier)
        self.init(identifier: identifier, ontology: ontology)

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
