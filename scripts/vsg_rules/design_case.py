"""VSG case rules for language constructs its built-in rules leave untouched."""

from vsg import parser, token
from vsg.rules import token_case
from vsg.rules.reserved.rule_001 import dMap

RESERVED = frozenset(dMap["all"])


class rule_500(token_case):
    """Cover keyword tokens including unary operators such as NOT and ABS."""

    def __init__(self):
        super().__init__([])
        self.name = "design_case"
        self.unique_id = self.get_unique_id()
        self.groups.append("case::keyword")

    def _get_tokens_of_interest(self, file):
        self.lTokens = {
            type(item) for item in file.lAllObjects
            if isinstance(item, parser.keyword) and item.get_lower_value() in RESERVED
        }
        return [
            match for match in super()._get_tokens_of_interest(file)
            if match.get_tokens()[0].get_lower_value() in RESERVED
        ]


class rule_501(token_case):
    """Format explicit architecture selections in instantiations and bindings."""

    def __init__(self):
        super().__init__([token.instantiated_unit.architecture_identifier, token.entity_aspect.architecture_identifier])
        self.name = "design_case"
        self.unique_id = self.get_unique_id()
        self.groups.append("case::name")


class rule_502(token_case):
    """Apply identifier case to enumeration values with basic names."""

    def __init__(self):
        super().__init__([token.enumeration_type_definition.enumeration_literal])
        self.name = "design_case"
        self.unique_id = self.get_unique_id()
        self.groups.append("case::name")

    def _get_tokens_of_interest(self, file):
        return [
            match for match in super()._get_tokens_of_interest(file)
            if match.get_tokens()[0].get_value()[:1].isalpha()
        ]
