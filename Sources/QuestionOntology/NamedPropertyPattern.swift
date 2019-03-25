
import ParserDescription


public struct NamedPropertyPattern<M>: Equatable
    where M: OntologyMappings
{
    public let pattern: Pattern
    public let propertyIdentifiers: Set<String>

    public static func == (lhs: NamedPropertyPattern<M>, rhs: NamedPropertyPattern<M>) -> Bool {
        // TODO: pattern
        return lhs.propertyIdentifiers == rhs.propertyIdentifiers
    }
}


extension NamedPropertyPattern: Codable {

    internal enum CodingKeys: String, CodingKey {
        case pattern
        case properties
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(TypedPattern(pattern), forKey: .pattern)
        if !propertyIdentifiers.isEmpty {
            try container.encode(
                propertyIdentifiers.sorted(),
                forKey: .properties
            )
        }
    }

    public init(from decoder: Decoder) throws {
        let codingUserInfo =
            try QuestionOntology<M>.codingUserInfo(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let pattern = try container.decode(TypedPattern.self, forKey: .pattern).pattern

        if let propertyIdentifiers =
            try container.decodeIfPresent(Set<String>.self, forKey: .properties)
        {
            for identifier in propertyIdentifiers {
                codingUserInfo.reference(property: identifier)
            }

            self.init(pattern: pattern, propertyIdentifiers: propertyIdentifiers)
        } else {
            self.init(pattern: pattern, propertyIdentifiers: [])
        }
    }
}
