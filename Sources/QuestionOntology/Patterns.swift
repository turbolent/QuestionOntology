
import ParserDescription
import ParserDescriptionOperators


public enum PartOfSpeech: String {
    case noun = "N"
    case verb = "V"

    var operation: Operation {
        switch self {
        case .noun, .verb:
            return .hasPrefix
        }
    }
}


private enum Label: String {
    case lemma
    case tag
}


public func pattern(lemma: String, partOfSpeech: PartOfSpeech) -> TokenPattern {
    return TokenPattern(condition:
        LabelCondition(
            label: Label.lemma.rawValue,
            op: .isEqualTo,
            input: lemma
        ) && LabelCondition(
            label: Label.tag.rawValue,
            op: partOfSpeech.operation,
            input: partOfSpeech.rawValue
        )
    )
}
