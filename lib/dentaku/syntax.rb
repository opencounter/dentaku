# [jneen]
# Welcome to the special sauce Opencounter custom parser!
# Overview:
#
# ========
# Tokenizer:
#   String -> enumerator(Token)
#
# First step is to transform the string into a stream (Enumerator) of
# tokens. This uses ruby's native StringScanner and regular expressions.
# Each token is responsible for knowing its location the source, and tokens
# are referenced all the way down from the AST. The token structure
# is defined in lib/dentaku/syntax/token.rb, and the location management
# and regular expressions are defined in lib/dentaku/syntax/tokenizer.rb
#
# Skeleton::Parser:
#   enumerator(Token) -> Skeleton
#
# Before parsing into a full AST, we first parse out all the nesting
# tokens: (parentheses), [square brackets], { curly brackes }, and case...end.
# This results in a tree of Skeleton::Token nodes and Skeleton::Nested nodes,
# which makes the actual parse much easier. The definition of the tree and
# the parser are both in lib/dentaku/syntax/skeleton.rb
#
# Parser:
#   Skeleton -> AST
#
# In Dentaku, it's not quite enough just to parse nesting tokens - the language
# comes with a variety of infix tokens as well as other expressions that span
# multiple skeleton trees. But since nesting delimiters are already nicely
# packed away by the skeleton tree, this can be done with a series of splits
# and basic pattern matching. This is contained in `parser.rb`.
require 'dentaku/syntax/token'
require 'dentaku/syntax/tokenizer'
require 'dentaku/syntax/skeleton'
require 'dentaku/syntax/parser'

module Dentaku
  module Syntax
    def self.parse(text, source_name: '<unknown>')
      tokens = Tokenizer.tokenize(source_name, text)
      skel = Skeleton.parse(tokens)
      ast = Parser.parse(skel)

      return ast
    end
  end
end
