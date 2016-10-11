require 'bigdecimal'
require 'dentaku/token'

module Dentaku
  class TokenScanner
    def initialize(category, regexp, converter=nil, condition=nil)
      @category  = category
      @regexp    = %r{\A(#{ regexp })}i
      @converter = converter
      @condition = condition || ->(*) { true }
    end

    def scan(string, last_token=nil)
      start = location(string)

      return false unless @condition.call(last_token) && string.scan(@regexp)

      value = raw = string[0]
      value = @converter.call(raw) if @converter

      return Array(value).map do |v|
        Token === v ? v : Token.new(@category, v, [start, location(string)], raw)
      end
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

    # for tests
    def scan_string(string, last_token=nil)
      scan(StringScanner.new(string), last_token)
    end

    class << self
      def available_scanners
        [
          :whitespace,
          :comment,
          :range,
          :numeric,
          :double_quoted_string,
          :single_quoted_string,
          :negate,
          :operator,
          :grouping,
          :dictionary,
          :list,
          :case_statement,
          :comparator,
          :combinator,
          :boolean,
          :function,
          :key,
          :identifier
        ]
      end

      def register_default_scanners
        register_scanners(available_scanners)
      end

      def register_scanners(scanner_ids)
        @scanners = scanner_ids.each_with_object({}) do |id, scanners|
          scanners[id] = self.send(id)
        end
      end

      def register_scanner(id, scanner)
        @scanners[id] = scanner
      end

      def scanners=(scanner_ids)
        @scanners.select! { |k,v| scanner_ids.include?(k) }
      end

      def scanners
        @scanners.values
      end

      def whitespace
        new(:whitespace, '\s+')
      end

      def comment
        new(:comment, /\/\*[^*]*\*+(?:[^*\/][^*]*\*+)*\//)
      end

      def numeric
        new(:numeric, '(\d+(\.\d+)?|\.\d+)\b', lambda { |raw| raw =~ /\./ ? BigDecimal.new(raw) : raw.to_i })
      end

      R = Struct.new(:range)
      def range
        converter = lambda do |raw|
          R.new(Range.new(*raw.split('..').map { |raw| raw =~ /\./ ? BigDecimal.new(raw) : raw.to_i }))
        end
        new(:range, '(\d+(\.\d+)?|\.\d+)\b\.\.(\d+(\.\d+)?|\.\d+)\b', converter)
      end

      def double_quoted_string
        new(:string, '"[^"]*"', lambda { |raw| raw.gsub(/^"|"$/, '') })
      end

      def single_quoted_string
        new(:string, "'[^']*'", lambda { |raw| raw.gsub(/^'|'$/, '') })
      end

      def negate
        new(:operator, '-', lambda { |raw| :negate }, lambda { |last_token|
          last_token.nil?             ||
          last_token.is?(:operator)   ||
          last_token.is?(:comparator) ||
          last_token.is?(:combinator) ||
          last_token.value == :open   ||
          last_token.value == :comma
        })
      end

      def operator
        names = { pow: '^', add: '+', subtract: '-', multiply: '*', divide: '/', mod: '%' }.invert
        new(:operator, '\^|\+|-|\*|\/|%', lambda { |raw| names[raw] })
      end

      def grouping
        names = { open: '(', close: ')', comma: ',' }.invert
        new(:grouping, /\(|\)|,(?=.*\))/m, lambda { |raw| names[raw] })
      end

      def case_statement
        names = { open: 'case', close: 'end', then: 'then', when: 'when', else: 'else' }.invert
        new(:case, '(case|end|then|when|else)\b', lambda { |raw| names[raw.downcase] })
      end

      def dictionary
        names = { open: '{', close: '}', comma: ',' }.invert
        new(:dictionary, '\{|\}|,(?=.*})', lambda { |raw| names[raw] })
      end

      def list
        names = { open: '[', close: ']', comma: ',' }.invert
        new(:list, '\[|\]|,(?=.*\])', lambda { |raw| names[raw] })
      end

      def key
        new(:key, '\w+\b:(?!\w)', lambda { |raw| raw.gsub(/:$/, '').strip.to_sym })
      end

      def comparator
        names = { le: '<=', ge: '>=', ne: '!=', lt: '<', gt: '>', eq: '=' }.invert
        alternate = { ne: '<>', eq: '==' }.invert
        new(:comparator, '<=|>=|!=|<>|<|>|==|=', lambda { |raw| names[raw] || alternate[raw] })
      end

      def combinator
        new(:combinator, '(and|or)\b', lambda { |raw| raw.strip.downcase.to_sym })
      end

      def boolean
        new(:logical, '(true|false)\b', lambda { |raw| raw.strip.downcase == 'true' })
      end

      def function
        new(:function, '\w+(?=\s*[(])', lambda { |raw| raw.downcase.to_sym })
      end

      def identifier
        new(:identifier, '[\w\:]+\b', lambda { |raw| raw.strip.downcase })
      end
    end

    register_default_scanners
  end
end
