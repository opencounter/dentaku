require 'strscan'

module Dentaku
  module Syntax
    class Tokenizer
      class LocRange
        def self.between(a, b)
          new(a.loc_range.begin, b.loc_range.end)
        end

        attr_reader :begin, :end
        def initialize(begin_, end_)
          @begin = begin_
          @end = end_
        end

        def as_json
          [@begin.as_json, @end.as_json]
        end

        def loc_range
          self
        end

        def slice(str)
          str.byteslice(begin_.byte, end_.byte)
        end

        def repr
          "{#{@begin.repr},#{@end.repr}}"
        end
      end

      class Location
        attr_reader :byte, :lineno, :colno
        def initialize(byte, lineno, colno)
          @byte = byte
          @lineno = lineno
          @colno = colno
        end

        def as_json
          { byte: @byte, line: @lineno, col: @colno }
        end

        def loc_range
          LocRange.new(self, self)
        end

        def repr
          "#{@lineno}:#{@colno}"
        end
      end

      MATCH = {
        :lparen => :rparen,
        :lbrack => :rbrack,
        :lbrace => :rbrace,
      }

      attr_reader :tokens, :scanner

      def self.tokenize(source_name, string)
        Tokenizer.new(source_name, string).call
      end

      def initialize(source_name, string)
        @tokens = []
        @source_name = source_name
        @input = string.to_s
        @scanner = StringScanner.new(@input)
        @initial = true
      end

      def byte_offset_to_index(index)
        @input.byteslice(0, index).length
      end

      def call(&b)
        return enum_for(:call) unless block_given?

        @lineno = 1
        @colno = 1
        until scanner.eos?
          start = self.location
          category, value = self.scan
          t = Token.new(category, value)
          t.source_name = @source_name
          t.original = @input
          t.loc_range = LocRange.between(start, self.location)

          yield t
        end
      end

    protected

      def find_colno(str)
        str =~ /^.*\z/ or return 0
        $&.size
      end

      def initial?
        !!@initial
      end

      def medial?
        !@initial
      end

      def m(groupnum=0)
        @scanner[groupnum]
      end

      def scan
        loop do
          next if match /\s+/
          next if match /\/\*[^*]*\*+(?:[^*\/][^*]*\*+)*\//
          next if match %r(//.*?$)
          break
        end

        return ini(:eof) if @scanner.eos?

        # literals and operators
        return med(:numeric, cast(m)) if match /(\d+(?:\.\d+)?|\.\d+)\b/

        # [jneen] idk why but the parentheses are considered match group 2 here
        return med(:string, unescape!(m 2)) if match /"((?:\\.|[^\\])*?)"/
        return med(:string, unescape!(m 2)) if match /'((?:\\.|[^\\])*?)'/

        return ini(:minus) if initial? && match(/[-]/)
        return ini(:exponential, m) if medial? && match(%r([*][*]|\^))
        return ini(:additive, m) if medial? && match(/[+-]/)
        return ini(:range) if medial? && match(/[.][.]/)
        return ini(:multiplicative, m) if medial? && match(%r([*/%]))
        return med(:logical, m.strip.downcase == 'true') if match /(true|false)\b/i

        # nests and commas
        return ini(:comma)  if match /,/m
        return ini(:lparen) if match /[(]/
        return med(:rparen) if match /[)]/
        return ini(:lbrace) if match /[{]/
        return med(:rbrace) if match /[}]/
        return ini(:lbrack) if match /\[/
        return med(:rbrack) if match /\]/

        # case
        return ini(:case) if match /case\b/i
        return med(:end)  if match /end\b/i
        return ini(:then) if match /then\b/i
        return ini(:when) if match /when\b/i
        return ini(:else) if match /else\b/i

        # infix ops
        return ini(:comparator, m.to_sym) if match /<=|>=|!=|<>|<|>|==|=/
        return ini(:combinator, m.strip.downcase.to_sym) if match /(and|or)\b/i

        # general identifiers
        return med(:key, (m 2).strip.to_sym) if \
          match /([[:alnum:]_]+\b):(?![[:alnum:]])/
        return med(:identifier, m.strip.downcase) if match /[[:alnum:]_:]+\b/

        return ini(:error, "unbalanced quote") if match /['"]/
        return ini(:error, "Unknown token starting with `#{(m + scanner.peek(2))}'") if match(/./)
      end

      def unescape!(str)
        str.gsub!(/\\(.)/) do |ch|
          case ch
          when '\\' then '\\'
          when 'n' then "\n"
          when 't' then "\t"
          when 'r' then "\r"
          else ch
          end
        end

        str
      end

      # used to mark tokens that expect expressions after them, like
      # open parens or infix operators
      def ini(*args)
        @initial = true
        args
      end

      # used to mark tokens that do not expect expressions after them, like
      # literals and identifiers
      def med(*args)
        @initial = false
        args
      end

      def cast(raw)
        raw =~ /\./ ? BigDecimal(raw) : raw.to_i
      end

      def match(regexp)
        matched = @scanner.scan(/\A(#{ regexp })/i)
        return false unless matched

        newlines = matched.scan(/\n/).size
        @lineno += newlines
        if newlines > 0
          @colno = find_colno(matched[0])
        else
          @colno += find_colno(matched[0])
        end

        true
      end

      def location
        Location.new(@scanner.pos, @lineno, @colno)
      end
    end
  end
end
