import Foundation
import QuestionOntology


protocol WikidataDefinition {
    init(identifier: String)
}


struct WikidataItem: OntologyMapping, WikidataDefinition {
    let identifier: String
}


struct WikidataProperty: OntologyMapping, WikidataDefinition {
    let identifier: String
}


struct Wikidata {

    @dynamicMemberLookup
    struct Factory<T> where T: WikidataDefinition {

        let prefix: String

        fileprivate init(prefix: String) {
            self.prefix = prefix
        }

        public subscript(dynamicMember id: String) -> T {
            guard Int(id) != nil else {
                fatalError("invalid non-numeric Wikidata ID: \(id)")
            }
            return T(identifier: prefix + id)
        }
    }

    static let Q = Factory<WikidataItem>(prefix: "http://www.wikidata.org/entity/Q")
    static let P = Factory<WikidataProperty>(prefix: "http://www.wikidata.org/prop/direct/P")
}


enum WikidataPropertyMapping: OntologyMapping {
    case property(WikidataProperty)
    case operation(WikidataOperation)
}


extension WikidataPropertyMapping {

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case property
        case operation
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .property(let property):
            try container.encode(property, forKey: .property)
        case .operation(let operation):
            try container.encode(operation, forKey: .operation)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        for codingKey in CodingKeys.allCases {
            switch codingKey {
            case .property:
                if let property =
                    try container.decodeIfPresent(WikidataProperty.self, forKey: .property)
                {
                    self = .property(property)
                    return
                }
            case .operation:
                if let operation =
                    try container.decodeIfPresent(WikidataOperation.self, forKey: .operation)
                {
                    self = .operation(operation)
                    return
                }
            }
        }

        let allProperties = Set(CodingKeys.allCases.map { $0.rawValue })
        throw QuestionOntologyDecodingError.missingPropertyOneOf(allProperties)
    }
}


enum WikidataOperation: Codable, Hashable {
    case age(birthDatePropertyIdentifier: String, deathDatePropertyIdentifier: String)

    static func age(
        birthDateProperty: Property<WikidataOntologyMappings>,
        deathDateProperty: Property<WikidataOntologyMappings>
    ) -> WikidataOperation {
        return .age(
            birthDatePropertyIdentifier: birthDateProperty.identifier,
            deathDatePropertyIdentifier: deathDateProperty.identifier
        )
    }
}


extension WikidataOperation {

    internal enum Types: String, CaseIterable {
        case age
    }

    internal enum CommonCodingKeys: String, CodingKey {
        case type
    }

    internal enum AgeCodingKeys: String, CodingKey {
        case birthDateProperty
        case deathDateProperty
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .age(let birthDatePropertyIdentifier, let deathDatePropertyIdentifier):
            var commonContainer = encoder.container(keyedBy: CommonCodingKeys.self)
            try commonContainer.encode(Types.age.rawValue, forKey: .type)

            var container = encoder.container(keyedBy: AgeCodingKeys.self)
            try container.encode(birthDatePropertyIdentifier, forKey: .birthDateProperty)
            try container.encode(deathDatePropertyIdentifier, forKey: .deathDateProperty)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CommonCodingKeys.self)
        guard let type = Types(rawValue: try container.decode(String.self, forKey: .type)) else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "invalid operation type"
            )
        }
        switch type {
        case .age:
            let container = try decoder.container(keyedBy: AgeCodingKeys.self)
            self = .age(
                birthDatePropertyIdentifier:
                    try container.decode(String.self, forKey: .birthDateProperty),
                deathDatePropertyIdentifier:
                    try container.decode(String.self, forKey: .deathDateProperty)
            )
        }
    }
}


struct WikidataOntologyMappings: OntologyMappings {
    typealias Class = WikidataItem
    typealias Individual = WikidataItem
    typealias Property = WikidataPropertyMapping
}
