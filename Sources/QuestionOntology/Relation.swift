import ParserDescription


public struct Relation<Mappings>: Hashable
    where Mappings: OntologyMappings
{
    public enum Direction: String, Hashable {
        case incoming
        case outgoing
    }

    public let direction: Direction
    public let propertyIdentifier: String
    public let pattern: AnyPattern?
}


extension Relation: Codable {

    internal enum CodingKeys: String, CodingKey {
        case direction
        case property
        case pattern
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(direction, forKey: .direction)
        try container.encode(propertyIdentifier, forKey: .property)
        try container.encodeIfPresent(pattern, forKey: .pattern)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let direction = try container.decode(Direction.self, forKey: .direction)
        let propertyIdentifier = try container.decode(String.self, forKey: .property)
        let pattern = try container.decodeIfPresent(AnyPattern.self, forKey: .pattern)

        self.init(
            direction: direction,
            propertyIdentifier: propertyIdentifier,
            pattern: pattern
        )
    }
}


extension Relation.Direction: Codable {}


extension Relation: Comparable {

    public static func < (lhs: Relation<Mappings>, rhs: Relation<Mappings>) -> Bool {
        return lhs.direction < rhs.direction
            || lhs.propertyIdentifier < rhs.propertyIdentifier
            // TODO: improve
            || String(describing: lhs.pattern) < String(describing: rhs.pattern)
    }
}

extension Relation.Direction: Comparable {

    private var orderIndex: Int {
        switch self {
        case .incoming:
            return 0
        case .outgoing:
            return 1
        }
    }

    public static func < (
        lhs: Relation.Direction,
        rhs: Relation.Direction
    ) -> Bool {
        switch (lhs, rhs) {
        case (.incoming, .incoming),
             (.outgoing, .outgoing):
            return false
        case (.incoming, _), (.outgoing, _):
            return lhs.orderIndex < rhs.orderIndex
        }
    }
}
