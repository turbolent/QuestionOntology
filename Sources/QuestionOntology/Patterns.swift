
import ParserDescription
import ParserDescriptionOperators


public enum Tag: String {
    case noun = "N"
    case verb = "V"
    case adjective = "JJ"

    var operation: Operation {
        switch self {
        case .noun, .verb, .adjective:
            return .hasPrefix
        }
    }
}


private enum Label: String {
    case lemma
    case tag
}


public func pattern(lemma: String, tag: Tag) -> TokenPattern {
    return TokenPattern(condition:
        LabelCondition(
            label: Label.lemma.rawValue,
            op: .isEqualTo,
            input: lemma
        ) && LabelCondition(
            label: Label.tag.rawValue,
            op: tag.operation,
            input: tag.rawValue
        )
    )
}
