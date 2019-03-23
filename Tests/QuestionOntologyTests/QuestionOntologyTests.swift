import XCTest
import QuestionOntology
import DiffedAssertEqual
import ParserDescription
import ParserDescriptionOperators


@available(OSX 10.13, *)
final class QuestionOntologyTests: XCTestCase {

    func testDefinitions() throws {

        let ontology = QuestionOntology<WikidataOntologyMappings>()

        let Person = ontology.define(class: "Person")
            .map(to: Wikidata.Q.5)
            .hasPattern(pattern(lemma: "person", partOfSpeech: .noun))
            .hasPattern(pattern(lemma: "people", partOfSpeech: .noun))

        let hasDateOfBirth = ontology.define(property: "hasDateOfBirth")
            .map(to: .property(Wikidata.P.569))

        let hasDateOfDeath = ontology.define(property: "hasDateOfDeath")
            .map(to: .property(Wikidata.P.570))

        ontology.define(property: "hasAge")
            .map(to: .operation(
                .age(
                    birthDateProperty: hasDateOfBirth,
                    deathDateProperty: hasDateOfDeath
                ))
            )

        let hasPlaceOfBirth = ontology.define(property: "hasPlaceOfBirth")
            .map(to: .property(Wikidata.P.19))

        let hasPlaceOfDeath = ontology.define(property: "hasPlaceOfDeath")
            .map(to: .property(Wikidata.P.20))

        let hasParent = ontology.define(property: "hasParent")

        let hasMother = ontology.define(property: "hasMother")
            .isSubPropertyOf(hasParent)
            .map(to: .property(Wikidata.P.25))

        let hasFather = ontology.define(property: "hasFather")
            .isSubPropertyOf(hasParent)
            .map(to: .property(Wikidata.P.22))

        let Gender = ontology.define(class: "Gender")

        let male = ontology.define(individual: "male")
            .isA(Gender)
            .map(to: Wikidata.Q.6581097)

        let female = ontology.define(individual: "female")
            .isA(Gender)
            .map(to: Wikidata.Q.6581072)

        let hasGender = ontology.define(property: "hasGender")

        let Male = ontology.define(class: "Male")
            .isSubClassOf(Person)
            .hasEquivalent(outgoing: hasGender, male)

        let Female = ontology.define(class: "Female")
            .isSubClassOf(Person)
            .hasEquivalent(outgoing: hasGender, female)

        let hasChild = ontology.define(property: "hasChild")
            .hasEquivalent(incoming: hasFather)
            .hasEquivalent(incoming: hasMother)

        hasParent.hasEquivalent(incoming: hasChild)

        let Parent = ontology.define(class: "Parent")
            .isSubClassOf(Person)
            .hasEquivalent(outgoing: hasChild)
            .hasPattern(pattern(lemma: "parent", partOfSpeech: .noun))

        ontology.define(class: "Mother")
            .isSubClassOf(Parent)
            .isSubClassOf(Female)
            .hasEquivalent(incoming: hasMother)
            .hasPattern(pattern(lemma: "mother", partOfSpeech: .noun))

        ontology.define(class: "Father")
            .isSubClassOf(Parent)
            .isSubClassOf(Male)
            .hasEquivalent(incoming: hasFather)
            .hasPattern(pattern(lemma: "father", partOfSpeech: .noun))

        let Child = ontology.define(class: "Child")
            .isSubClassOf(Person)
            .hasEquivalent(incoming: hasChild)
            .hasPattern(pattern(lemma: "child", partOfSpeech: .noun))

        ontology.define(class: "Daughter")
            .isSubClassOf(Child)
            .isSubClassOf(Female)
            .hasPattern(pattern(lemma: "daughter", partOfSpeech: .noun))

        ontology.define(class: "Son")
            .isSubClassOf(Child)
            .isSubClassOf(Male)
            .hasPattern(pattern(lemma: "son", partOfSpeech: .noun))

        ontology.define(property: "hasSpouse")
            .makeSymmetric()
            .map(to: .property(Wikidata.P.26))

        let Spouse = ontology.define(class: "Spouse")
            .hasPattern(pattern(lemma: "spouse", partOfSpeech: .noun))

        ontology.define(class: "Wife")
            .isSubClassOf(Spouse)
            .isSubClassOf(Female)
            .map(to: Wikidata.Q.188830)
            .hasPattern(pattern(lemma: "wife", partOfSpeech: .noun))

        ontology.define(class: "Husband")
            .isSubClassOf(Spouse)
            .isSubClassOf(Male)
            .map(to: Wikidata.Q.212878)
            .hasPattern(pattern(lemma: "husband", partOfSpeech: .noun))

        let hasSibling = ontology.define(property: "hasSibling")
            .makeSymmetric()
            .map(to: .property(Wikidata.P.3373))

        let Sibling = ontology.define(class: "Sibling")
            .isSubClassOf(Person)
            .hasEquivalent(outgoing: hasSibling)
            .hasPattern(pattern(lemma: "sibling", partOfSpeech: .noun))

        ontology.define(class: "Sister")
            .isSubClassOf(Sibling)
            .isSubClassOf(Female)
            .hasPattern(pattern(lemma: "sister", partOfSpeech: .noun))

        ontology.define(class: "Brother")
            .isSubClassOf(Sibling)
            .isSubClassOf(Male)
            .hasPattern(pattern(lemma: "brother", partOfSpeech: .noun))

        let GrandParent = ontology.define(class: "GrandParent")
            .isSubClassOf(Parent)
            .hasEquivalent(
                outgoing: hasChild,
                outgoing: hasChild
            )
            .hasPattern(pattern(lemma: "grandparent", partOfSpeech: .noun))

        ontology.define(class: "GrandMother")
            .isSubClassOf(GrandParent)
            .isSubClassOf(Female)
            .hasPattern(pattern(lemma: "grandmother", partOfSpeech: .noun))

        ontology.define(class: "GrandFather")
            .isSubClassOf(GrandParent)
            .isSubClassOf(Male)
            .hasPattern(pattern(lemma: "grandfather", partOfSpeech: .noun))

        let GrandChild = ontology.define(class: "GrandChild")
            .isSubClassOf(Child)
            .hasEquivalent(
                incoming: hasChild,
                incoming: hasChild
            )
            .hasPattern(pattern(lemma: "grandchild", partOfSpeech: .noun))

        ontology.define(class: "GrandDaughter")
            .isSubClassOf(GrandChild)
            .isSubClassOf(Female)
            .hasPattern(pattern(lemma: "granddaughter", partOfSpeech: .noun))

        ontology.define(class: "GrandSon")
            .isSubClassOf(GrandChild)
            .isSubClassOf(Male)
            .hasPattern(pattern(lemma: "grandson", partOfSpeech: .noun))

        diffedAssertJSONEqual(
            """
            {
              "class_mapping" : {
                "Husband" : {
                  "identifier" : "http://www.wikidata.org/entity/Q212878"
                },
                "Person" : {
                  "identifier" : "http://www.wikidata.org/entity/Q5"
                },
                "Wife" : {
                  "identifier" : "http://www.wikidata.org/entity/Q188830"
                }
              },
              "classes" : [
                {
                  "identifier" : "Brother",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "brother",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Male",
                    "Sibling"
                  ]
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "incoming" : "hasChild"
                      }
                    ]
                  ],
                  "identifier" : "Child",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "child",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Person"
                  ]
                },
                {
                  "identifier" : "Daughter",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "daughter",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Child",
                    "Female"
                  ]
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "incoming" : "hasFather"
                      }
                    ]
                  ],
                  "identifier" : "Father",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "father",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Male",
                    "Parent"
                  ]
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "outgoing" : "hasGender"
                      },
                      {
                        "individual" : "female"
                      }
                    ]
                  ],
                  "identifier" : "Female",
                  "superclasses" : [
                    "Person"
                  ]
                },
                {
                  "identifier" : "Gender"
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "incoming" : "hasChild"
                      },
                      {
                        "incoming" : "hasChild"
                      }
                    ]
                  ],
                  "identifier" : "GrandChild",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "grandchild",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Child"
                  ]
                },
                {
                  "identifier" : "GrandDaughter",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "granddaughter",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Female",
                    "GrandChild"
                  ]
                },
                {
                  "identifier" : "GrandFather",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "grandfather",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "GrandParent",
                    "Male"
                  ]
                },
                {
                  "identifier" : "GrandMother",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "grandmother",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Female",
                    "GrandParent"
                  ]
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "outgoing" : "hasChild"
                      },
                      {
                        "outgoing" : "hasChild"
                      }
                    ]
                  ],
                  "identifier" : "GrandParent",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "grandparent",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Parent"
                  ]
                },
                {
                  "identifier" : "GrandSon",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "grandson",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "GrandChild",
                    "Male"
                  ]
                },
                {
                  "identifier" : "Husband",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "husband",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Male",
                    "Spouse"
                  ]
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "outgoing" : "hasGender"
                      },
                      {
                        "individual" : "male"
                      }
                    ]
                  ],
                  "identifier" : "Male",
                  "superclasses" : [
                    "Person"
                  ]
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "incoming" : "hasMother"
                      }
                    ]
                  ],
                  "identifier" : "Mother",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "mother",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Female",
                    "Parent"
                  ]
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "outgoing" : "hasChild"
                      }
                    ]
                  ],
                  "identifier" : "Parent",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "parent",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Person"
                  ]
                },
                {
                  "identifier" : "Person",
                  "pattern" : {
                    "patterns" : [
                      {
                        "condition" : {
                          "conditions" : [
                            {
                              "input" : "person",
                              "label" : "lemma",
                              "op" : "=",
                              "type" : "label"
                            },
                            {
                              "input" : "N",
                              "label" : "tag",
                              "op" : "prefix",
                              "type" : "label"
                            }
                          ],
                          "type" : "and"
                        },
                        "type" : "token"
                      },
                      {
                        "condition" : {
                          "conditions" : [
                            {
                              "input" : "people",
                              "label" : "lemma",
                              "op" : "=",
                              "type" : "label"
                            },
                            {
                              "input" : "N",
                              "label" : "tag",
                              "op" : "prefix",
                              "type" : "label"
                            }
                          ],
                          "type" : "and"
                        },
                        "type" : "token"
                      }
                    ],
                    "type" : "or"
                  }
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "outgoing" : "hasSibling"
                      }
                    ]
                  ],
                  "identifier" : "Sibling",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "sibling",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Person"
                  ]
                },
                {
                  "identifier" : "Sister",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "sister",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Female",
                    "Sibling"
                  ]
                },
                {
                  "identifier" : "Son",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "son",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Child",
                    "Male"
                  ]
                },
                {
                  "identifier" : "Spouse",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "spouse",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  }
                },
                {
                  "identifier" : "Wife",
                  "pattern" : {
                    "condition" : {
                      "conditions" : [
                        {
                          "input" : "wife",
                          "label" : "lemma",
                          "op" : "=",
                          "type" : "label"
                        },
                        {
                          "input" : "N",
                          "label" : "tag",
                          "op" : "prefix",
                          "type" : "label"
                        }
                      ],
                      "type" : "and"
                    },
                    "type" : "token"
                  },
                  "superclasses" : [
                    "Female",
                    "Spouse"
                  ]
                }
              ],
              "individual_mapping" : {
                "female" : {
                  "identifier" : "http://www.wikidata.org/entity/Q6581072"
                },
                "male" : {
                  "identifier" : "http://www.wikidata.org/entity/Q6581097"
                }
              },
              "individuals" : [
                {
                  "identifier" : "female",
                  "types" : [
                    "Gender"
                  ]
                },
                {
                  "identifier" : "male",
                  "types" : [
                    "Gender"
                  ]
                }
              ],
              "properties" : [
                {
                  "identifier" : "hasAge"
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "incoming" : "hasFather"
                      }
                    ],
                    [
                      {
                        "incoming" : "hasMother"
                      }
                    ]
                  ],
                  "identifier" : "hasChild"
                },
                {
                  "identifier" : "hasDateOfBirth"
                },
                {
                  "identifier" : "hasDateOfDeath"
                },
                {
                  "identifier" : "hasFather",
                  "superproperties" : [
                    "hasParent"
                  ]
                },
                {
                  "identifier" : "hasGender"
                },
                {
                  "identifier" : "hasMother",
                  "superproperties" : [
                    "hasParent"
                  ]
                },
                {
                  "equivalencies" : [
                    [
                      {
                        "incoming" : "hasChild"
                      }
                    ]
                  ],
                  "identifier" : "hasParent"
                },
                {
                  "identifier" : "hasPlaceOfBirth"
                },
                {
                  "identifier" : "hasPlaceOfDeath"
                },
                {
                  "identifier" : "hasSibling",
                  "symmetric" : true
                },
                {
                  "identifier" : "hasSpouse",
                  "symmetric" : true
                }
              ],
              "property_mapping" : {
                "hasAge" : {
                  "operation" : {
                    "birthDateProperty" : "hasDateOfBirth",
                    "deathDateProperty" : "hasDateOfDeath",
                    "type" : "age"
                  }
                },
                "hasDateOfBirth" : {
                  "property" : {
                    "identifier" : "http://www.wikidata.org/prop/direct/P569"
                  }
                },
                "hasDateOfDeath" : {
                  "property" : {
                    "identifier" : "http://www.wikidata.org/prop/direct/P570"
                  }
                },
                "hasFather" : {
                  "property" : {
                    "identifier" : "http://www.wikidata.org/prop/direct/P22"
                  }
                },
                "hasMother" : {
                  "property" : {
                    "identifier" : "http://www.wikidata.org/prop/direct/P25"
                  }
                },
                "hasPlaceOfBirth" : {
                  "property" : {
                    "identifier" : "http://www.wikidata.org/prop/direct/P19"
                  }
                },
                "hasPlaceOfDeath" : {
                  "property" : {
                    "identifier" : "http://www.wikidata.org/prop/direct/P20"
                  }
                },
                "hasSibling" : {
                  "property" : {
                    "identifier" : "http://www.wikidata.org/prop/direct/P3373"
                  }
                },
                "hasSpouse" : {
                  "property" : {
                    "identifier" : "http://www.wikidata.org/prop/direct/P26"
                  }
                }
              }
            }
            """,
            ontology
        )

        let encoded = try JSONEncoder().encode(ontology)

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)

        let decodedOntology =
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded
            )

        XCTAssertEqual(ontology, decodedOntology)
    }

    func testInvalidSuperProperties() throws {
        let encoded = """
        {
          "properties": [
            {
              "identifier": "foo",
              "superproperties": ["non-existent"]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedPropertyIdentifiers(["non-existent"]), error)
        }
    }

    func testInvalidPropertyEquivalencies() throws {
        let encoded = """
        {
          "properties": [
            {
              "identifier": "foo",
              "equivalencies": [
                [
                  {"incoming": "non-existent"}
                ]
              ]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedPropertyIdentifiers(["non-existent"]), error)
        }
    }

    func testInvalidClassEquivalencies() throws {
        let encoded = """
        {
          "classes": [
            {
              "identifier": "foo",
              "equivalencies": [
                [
                  {"outgoing": "non-existent"}
                ]
              ]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedPropertyIdentifiers(["non-existent"]), error)
        }
    }

    func testInvalidClassEquivalencies2() throws {
        let encoded = """
        {
          "classes": [
            {
              "identifier": "foo",
              "equivalencies": [
                [
                  {"individual": "non-existent"}
                ]
              ]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedIndividualIdentifiers(["non-existent"]), error)
        }
    }

    func testInvalidSuperClasses() throws {
        let encoded = """
        {
          "classes": [
            {
              "identifier": "foo",
              "superclasses": ["non-existent"]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedClassIdentifiers(["non-existent"]), error)
        }
    }

    func testInvalidTypes() throws {
        let encoded = """
        {
          "individuals": [
            {
              "identifier": "foo",
              "types": ["non-existent"]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        QuestionOntology<WikidataOntologyMappings>.prepare(decoder: decoder)
        XCTAssertThrowsError(
            try decoder.decode(
                QuestionOntology<WikidataOntologyMappings>.self,
                from: encoded.data(using: .utf8)!
            )
        ) {
            guard let error = $0 as? QuestionOntologyDecodingError else {
                XCTFail("unexpected error: \($0)")
                return
            }
            XCTAssertEqual(.undefinedClassIdentifiers(["non-existent"]), error)
        }
    }
}
