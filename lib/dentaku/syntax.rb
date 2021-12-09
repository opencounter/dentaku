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
