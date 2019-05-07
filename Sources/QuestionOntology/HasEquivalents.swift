
public protocol HasEquivalents {
    associatedtype Mappings: OntologyMappings
    func hasEquivalent(_ equivalent: Equivalent<Mappings>) -> Self
}


public extension HasEquivalents {

    @discardableResult
    func hasEquivalent(
        outgoing: HasPropertyIdentifier,
        _ individual: HasIndividualIdentifier
    )
        -> Self
    {
        return hasEquivalent(.segments([
            .outgoing(outgoing),
            .individual(individual)
        ]))
    }

    @discardableResult
    func hasEquivalent(outgoing: HasPropertyIdentifier) -> Self {
        return hasEquivalent(.segments([
            .outgoing(outgoing)
        ]))
    }

    @discardableResult
    func hasEquivalent(
        outgoing: HasPropertyIdentifier,
        outgoing secondOutgoing: HasPropertyIdentifier
    ) -> Self {
        return hasEquivalent(.segments([
            .outgoing(outgoing),
            .outgoing(secondOutgoing)
        ]))
    }

    @discardableResult
    func hasEquivalent(
        outgoing: HasPropertyIdentifier,
        incoming: HasPropertyIdentifier
    )
        -> Self
    {
        return hasEquivalent(.segments([
            .outgoing(outgoing),
            .incoming(incoming)
        ]))
    }

    @discardableResult
    func hasEquivalent(
        individual: HasIndividualIdentifier,
        incoming: HasPropertyIdentifier
    )
        -> Self
    {
        return hasEquivalent(.segments([
            .individual(individual),
            .incoming(incoming)
        ]))
    }

    @discardableResult
    func hasEquivalent(incoming: HasPropertyIdentifier) -> Self {
        return hasEquivalent(.segments([
            .incoming(incoming)
        ]))
    }

    @discardableResult
    func hasEquivalent(
        incoming: HasPropertyIdentifier,
        incoming secondIncoming: HasPropertyIdentifier
    ) -> Self {
        return hasEquivalent(.segments([
            .incoming(incoming),
            .incoming(secondIncoming)
        ]))
    }

    @discardableResult
    func hasEquivalent(
        incoming: HasPropertyIdentifier,
        outgoing: HasPropertyIdentifier
    )
        -> Self
    {
        return hasEquivalent(.segments([
            .incoming(incoming),
            .outgoing(outgoing)
        ]))
    }
}
