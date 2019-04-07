// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "QuestionOntology",
    products: [
        .library(
            name: "QuestionOntology",
            targets: ["QuestionOntology"]
        ),
        .library(
            name: "TestQuestionOntology",
            targets: ["TestQuestionOntology"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/turbolent/DiffedAssertEqual.git", from: "0.2.0"),
        .package(url: "https://github.com/turbolent/ParserDescription.git", from: "0.5.0"),
    ],
    targets: [
        .target(
            name: "QuestionOntology",
            dependencies: [
                "ParserDescription",
                "ParserDescriptionOperators"
            ]
        ),
        .target(
            name: "TestQuestionOntology",
            dependencies: [
                "QuestionOntology",
                "ParserDescription",
                "ParserDescriptionOperators"
            ]
        ),
        .testTarget(
            name: "QuestionOntologyTests",
            dependencies: [
                "QuestionOntology",
                "TestQuestionOntology",
                "DiffedAssertEqual",
                "ParserDescription",
                "ParserDescriptionOperators"
            ]
        ),
    ]
)
