require 'strscan'
require 'dentaku/token'

module Dentaku
  class Tokenizer
    NAMES = {
      operator: { pow: '^', add: '+', subtract: '-', multiply: '*', divide: '/', mod: '%' }.invert,
      grouping: { open: '(', close: ')', comma: ',' }.invert,
      dictionary: { open: '{', close: '}', comma: ',' }.invert,
      list: { open: '[', close: ']', comma: ',' }.invert,
      case: { open: 'case', close: 'end', then: 'then', when: 'when', else: 'else' }.invert,
      comparator: {
        le: '<=', ge: '>=', ne: '!=', lt: '<', gt: '>', eq: '='
      }.invert.merge({ ne: '<>', eq: '==' }.invert),
    }

    attr_reader :tokens, :scanner

    def self.tokenize(string)
      Tokenizer.new(string).call
    end

    def initialize(string)
      @tokens = []
      @nesting = 0
      @scanner = StringScanner.new(string.to_s)
    end

    def call
      until scanner.eos?
        start = location(scanner)
        category, value = scan

        @tokens << Token.new(
          category,
          value,
          [start, location(scanner)],
          scanner.matched
        ) unless [:whitespace, :comment].include? category
      end

      raise ParseError, "too many closing parentheses" if @nesting < 0
      raise ParseError, "too many opening parentheses" if @nesting > 0

      @tokens
    end

    private

    def scan
      if match /\s+/
        [:whitespace]
      elsif match /\/\*[^*]*\*+(?:[^*\/][^*]*\*+)*\//
        [:comment]
      elsif match /#{numeric}\.\.#{numeric}/
        [:range, Range.new(cast(scanner[2]), cast(scanner[3]))]
      elsif match numeric
        [:numeric, cast(scanner[0])]
      elsif match /(?<delim>['"])(?<str>.*?)\k<delim>/
        [:string, scanner[2]]
      elsif can_negate? && match(/\-/)
        [:operator, :negate]
      elsif match /\^|\+|-|\*|\/|%/
        [:operator, NAMES[:operator][scanner[0]]]
      elsif match /\(|\)|,(?=.*\))/m
        type = NAMES[:grouping][scanner[0]]
        case type
        when :open
          @nesting += 1
        when :close
          @nesting -= 1
        end

        [:grouping, type]
      elsif match /\{|\}|,(?=.*\})/
        [:dictionary, NAMES[:dictionary][scanner[0]]]
      elsif match /\[|\]|,(?=.*\])/
        [:list, NAMES[:list][scanner[0]]]
      elsif match /(case|end|then|when|else)\b/i
        [:case, NAMES[:case][scanner[1].downcase]]
      elsif match /<=|>=|!=|<>|<|>|==|=/
        [:comparator, NAMES[:comparator][scanner[0]]]
      elsif match /(and|or)\b/i
        [:combinator, scanner[0].strip.downcase.to_sym]
      elsif match /(true|false)\b/i
        [:logical, scanner[0].strip.downcase == 'true']
      elsif match /\w+(?=\s*[(])/
        [:function, scanner[0].downcase.to_sym]
      elsif match /(\w+\b):(?!\w)/
        [:key, scanner[2].strip.to_sym]
      elsif match /[\w\:]+\b/
        [:identifier, scanner[0].strip.downcase]
      else
        puts @tokens
        raise ParseError, "parse error at: '#{ scanner.string[0..scanner.pos-1] }'"
      end
    end

    def can_negate?
      last_token = @tokens.last
      last_token.nil?             ||
        last_token.is?(:operator)   ||
        last_token.is?(:comparator) ||
        last_token.is?(:combinator) ||
        last_token.value == :open   ||
        last_token.value == :comma
    end

    def numeric
      /(\d+(?:\.\d+)?|\.\d+)\b/
    end

    def cast(raw)
      raw =~ /\./ ? BigDecimal.new(raw) : raw.to_i
    end

    def match(regexp)
      @scanner.scan %r{\A(#{ regexp })}i
    end

    def location(scanner)
      line = scanner.string[0..scanner.pos-1].count("\n") + 1
      if line == 1
        col = scanner.pos + 1
      else
        col = scanner.string[0..scanner.pos-1].reverse.index("\n")
      end

      [line, col]
    end
  end
end
