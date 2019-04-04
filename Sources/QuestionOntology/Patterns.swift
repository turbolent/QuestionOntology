
import ParserDescription
import ParserDescriptionOperators


public enum Tag: String {
    case anyNoun = "N"
    case anyVerb = "V"
    case anyAdjective = "JJ"
    case comparativeAdjective = "JJR"
    case prepositionOrSubordinatingConjunction = "IN"

    var operation: Operation {
        switch self {
        case .anyNoun, .anyVerb, .anyAdjective:
            return .hasPrefix
        case .comparativeAdjective, .prepositionOrSubordinatingConjunction:
            return .isEqualTo
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
