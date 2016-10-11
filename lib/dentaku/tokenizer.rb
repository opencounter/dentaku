require 'dentaku/token'
require 'dentaku/token_matcher'
require 'dentaku/token_scanner'

# stdlib
require 'strscan'

module Dentaku
  class Tokenizer
    LPAREN = TokenMatcher.new(:grouping, :open)
    RPAREN = TokenMatcher.new(:grouping, :close)

    def tokenize(string)
      @nesting = 0
      @tokens  = []
      input    = StringScanner.new(string.to_s)

      until input.eos?
        unless TokenScanner.scanners.any? { |scanner| scan(input, scanner) }
          raise ParseError, "parse error at: '#{ input }'"
        end
      end

      raise ParseError, "too many opening parentheses" if @nesting > 0

      @tokens
    end

    def last_token
      @tokens.last
    end

    def scan(input, scanner)
      tokens = scanner.scan(input, last_token)
      return false unless tokens

      tokens.each do |token|
        raise "unexpected zero-width match (:#{ token.category }) at '#{ string }'" if token.length == 0

        @nesting += 1 if LPAREN == token
        @nesting -= 1 if RPAREN == token
        raise ParseError, "too many closing parentheses" if @nesting < 0

        @tokens << token unless token.is?(:whitespace) || token.is?(:comment)
      end

      true
    end
  end
end
