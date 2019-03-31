

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
            .outgoing(outgoing),
            .individual(individual)
        ]))
    }

    @discardableResult
    func hasEquivalent(outgoing: Property<M>) -> Self {
        return hasEquivalent(.segments([
            .outgoing(outgoing)
        ]))
    }

    @discardableResult
    func hasEquivalent(
        outgoing: Property<M>,
        outgoing secondOutgoing: Property<M>
    ) -> Self {
        return hasEquivalent(.segments([
            .outgoing(outgoing),
            .outgoing(secondOutgoing)
        ]))
    }

    @discardableResult
    func hasEquivalent(outgoing: Property<M>, incoming: Property<M>) -> Self {
        return hasEquivalent(.segments([
            .outgoing(outgoing),
            .incoming(incoming)
        ]))
    }

    @discardableResult
    func hasEquivalent(individual: Individual<M>, incoming: Property<M>) -> Self {
        return hasEquivalent(.segments([
            .individual(individual),
            .incoming(incoming)
        ]))
    }

    @discardableResult
    func hasEquivalent(incoming: Property<M>) -> Self {
        return hasEquivalent(.segments([
            .incoming(incoming)
        ]))
    }

    @discardableResult
    func hasEquivalent(
        incoming: Property<M>,
        incoming secondIncoming: Property<M>
    ) -> Self {
        return hasEquivalent(.segments([
            .incoming(incoming),
            .incoming(secondIncoming)
        ]))
    }

    @discardableResult
    func hasEquivalent(incoming: Property<M>, outgoing: Property<M>) -> Self {
        return hasEquivalent(.segments([
            .incoming(incoming),
            .outgoing(outgoing)
        ]))
    }
}
