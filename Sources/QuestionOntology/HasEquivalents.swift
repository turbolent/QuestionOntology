

public protocol HasEquivalents: class {
    associatedtype M: OntologyMappings
    var equivalents: Set<Equivalent<M>> { get set }
}

public extension HasEquivalents {
    @discardableResult
    func hasEquivalent(_ equivalent: Equivalent<M>) -> Self {
        equivalents.insert(equivalent)
        return self
    }

    @discardableResult
    func hasEquivalent(outgoing: Property<M>, _ individual: Individual<M>) -> Self {
        return hasEquivalent(.segments([
            .outgoing(outgoing.identifier),
            .individual(individual.identifier)
        ]))
    }

    @discardableResult
    func hasEquivalent(outgoing: Property<M>) -> Self {
        return hasEquivalent(.segments([
            .outgoing(outgoing.identifier)
        ]))
    }

    @discardableResult
    func hasEquivalent(
        outgoing: Property<M>,
        outgoing secondOutgoing: Property<M>
    ) -> Self {
        return hasEquivalent(.segments([
            .outgoing(outgoing.identifier),
            .outgoing(secondOutgoing.identifier)
        ]))
    }

    @discardableResult
    func hasEquivalent(outgoing: Property<M>, incoming: Property<M>) -> Self {
        return hasEquivalent(.segments([
            .outgoing(outgoing.identifier),
            .incoming(incoming.identifier)
        ]))
    }

    @discardableResult
    func hasEquivalent(individual: Individual<M>, incoming: Property<M>) -> Self {
        return hasEquivalent(.segments([
            .individual(individual.identifier),
            .incoming(incoming.identifier)
        ]))
    }

    @discardableResult
    func hasEquivalent(incoming: Property<M>) -> Self {
        return hasEquivalent(.segments([
            .incoming(incoming.identifier)
        ]))
    }

    @discardableResult
    func hasEquivalent(
        incoming: Property<M>,
        incoming secondIncoming: Property<M>
    ) -> Self {
        return hasEquivalent(.segments([
            .incoming(incoming.identifier),
            .incoming(secondIncoming.identifier)
        ]))
    }

    @discardableResult
    func hasEquivalent(incoming: Property<M>, outgoing: Property<M>) -> Self {
        return hasEquivalent(.segments([
            .incoming(incoming.identifier),
            .outgoing(outgoing.identifier)
        ]))
    }
}
