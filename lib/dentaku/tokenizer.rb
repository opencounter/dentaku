require 'strscan'
require 'dentaku/token'

module Dentaku
  class Tokenizer
    NAMES = {
      operator: {
        '^'  => :pow,
        '+'  => :add,
        '-'  => :subtract,
        '*'  => :multiply,
        '/'  => :divide,
        '%'  => :mod,
        '..' => :range
      }.freeze,
      grouping: {
        '(' => :open,
        ')' => :close,
        ',' => :comma,
      }.freeze,
      struct: {
        '{' => :open,
        '}' => :close,
        ',' => :comma,
      }.freeze,
      list: {
        '[' => :open,
        ']' => :close,
        ',' => :comma,
      }.freeze,
      case: {
        'case' => :open,
        'end' => :close,
        'then' => :then,
        'when' => :when,
        'else' => :else,
      }.freeze,
      comparator: {
        '<=' => :le,
        '>=' => :ge,
        '!=' => :ne,
        '<>' => :ne,
        '<'  => :lt,
        '>'  => :gt,
        '='  => :eq,
        '==' => :eq,
      }.freeze,
    }.freeze

    attr_reader :tokens, :scanner

    def self.tokenize(string)
      Tokenizer.new(string).call
    end

    def initialize(string)
      @tokens = []
      @input = string.to_s
      @pairs = Hash.new { |h, k| h[k] = [] }
      @scanner = StringScanner.new(@input)
    end

    def byte_offset_to_index(index)
      @input.byteslice(0, index).length
    end

    def call
      stack = []
      until scanner.eos?
        start_i = byte_offset_to_index(scanner.pos)
        start = location(scanner)
        category, value = scan(stack.last)
        end_i = byte_offset_to_index(scanner.pos) - 1

        token = Token.new(
          category,
          value,
          (start_i..end_i),
          [start, location(scanner)],
          scanner.matched
        )

        stack.push(category) if value == :open
        stack.pop if value == :close

        @tokens << token unless [:whitespace, :comment].include? category
        add_pair_token(token) if [:open, :close].include?(value)
      end

      assert_pairs!

      @tokens
    end

    private

    def scan(parent_category=nil)
      if match /\s+/
        [:whitespace]
      elsif match /\/\*[^*]*\*+(?:[^*\/][^*]*\*+)*\//
        [:comment]
      elsif match numeric
        [:numeric, cast(scanner[0])]
      elsif match /(?<delim>['"])(?<str>.*?)\k<delim>/
        [:string, scanner[2]]
      elsif can_negate? && match(/\-/)
        [:operator, :negate]
      elsif match %r(\^|[+]|[-]|[*]|[/]|[%]|[.][.])
        [:operator, NAMES[:operator][scanner[0]]]
      elsif match /,/m
        raise ParseError.new("comma found outside of group", location(scanner)) unless parent_category
        [parent_category, NAMES[parent_category][scanner[0]]]
      elsif match /\(|\)|,(?=.*\))/m
        [:grouping, NAMES[:grouping][scanner[0]]]
      elsif match /\{|\}|,(?=.*\})/
        [:struct, NAMES[:struct][scanner[0]]]
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
      elsif match /[[:alnum:]_]+(?=\s*[(])/
        [:function, scanner[0].downcase.to_sym]
      elsif match /([[:alnum:]_]+\b):(?![[:alnum:]])/
        [:key, scanner[2].strip.to_sym]
      elsif match /[[:alnum:]_:]+\b/
        [:identifier, scanner[0].strip.downcase]
      elsif match /['"]/
        raise ParseError.new("unbalanced quote", location(scanner))
      else
        raise ParseError.new("Unknown token starting with #{scanner.peek(3).inspect}", location(scanner))
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
      raw =~ /\./ ? BigDecimal(raw) : raw.to_i
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

    def add_pair_token(token)
      @pairs[token.category] << token
    end

    def assert_pairs!
      @pairs.values.each do |tokens|
        assert_even_tokens!(tokens)
      end
    end

    def assert_even_tokens!(tokens)
      opens = []
      closes = []
      tokens.each do |token|
        if(token.value == :close && !opens.empty?)
          opens.pop
        elsif(token.value == :close)
          closes << token
        else
          opens << token
        end
      end

      return if opens.empty? && closes.empty?

      bad_token = closes.first || opens.first
      message = if bad_token.value == :open
                  "'#{symbol(bad_token)}' missing closing '#{matching_symbol(bad_token)}'"
                else
                  "extraneous closing '#{symbol(bad_token)}' for '#{matching_symbol(bad_token)}'"
                end
      raise ParseError.new(message, bad_token)
    end

    def matching_symbol(token)
      symbol(token, true)
    end

    def symbol(token, invert=false)
      value = invert ? (token.value == :open ? :close : :open) : token.value
      NAMES[token.category].invert[value].upcase
    end
  end
end
