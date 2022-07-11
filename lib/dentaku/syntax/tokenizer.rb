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
          raise "invalid loc_range #{@begin.inspect}..#{@end.inspect}" unless @begin.is_a?(Location) && @end.is_a?(Location)
        end

        def as_json(*)
          [@begin.as_json, @end.as_json]
        end

        def loc_range
          self
        end

        def index_range
          (@begin.index...@end.index)
        end

        def byte_range
          (@begin.byte...@end.byte)
        end

        def slice(str)
          str.byteslice(byte_range)
        end

        def repr
          "{#{@begin.repr},#{@end.repr}}"
        end
      end

      class Location
        attr_reader :byte, :index, :lineno, :colno
        def initialize(byte, index, lineno, colno)
          @byte = byte
          @index = index
          @lineno = lineno
          @colno = colno
        end

        def as_json(*)
          { byte: @byte, index: @index, line: @lineno, col: @colno }
        end

        def loc_range
          LocRange.new(self, self)
        end

        def repr
          "#{@lineno}:#{@colno}"
        end
      end

      attr_reader :tokens, :scanner

      def self.tokenize(source_name, string)
        Tokenizer.new(source_name, string).call
      end

      def initialize(source_name, string)
        @tokens = []
        @source_name = source_name
        @input = string.to_s

        # [jneen] fixed_anchor requires at least ruby 2.6
        @scanner = StringScanner.new(@input, fixed_anchor: true)

        @initial = true
      end

      def byte_offset_to_index(index)
        @input.byteslice(0, index).length
      end

      def call(&b)
        return enum_for(:call) unless block_given?

        @index = 0
        @lineno = 1
        @colno = 1
        until scanner.eos?
          skip_whitespace_and_comments

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
        str.rpartition("\n").last.size
      end

      def initial?
        !!@initial
      end

      def medial?
        !@initial
      end

      # super-short-form way of accessing the last match or match group
      def m(groupnum=0)
        @scanner[groupnum]
      end

      def skip_whitespace_and_comments
        match %r(
          (?: \s+
            | //.*?$
            | /[*].*?[*]/
          )+
        )mx
      end

      def scan
        return ini(:eof) if @scanner.eos?

        # nests and commas
        return ini(:comma)  if match /,/m
        return ini(:lparen) if match /[(]/
        return med(:rparen) if match /[)]/
        return ini(:lbrace) if match /[{]/
        return med(:rbrace) if match /[}]/
        return ini(:lbrack) if match /\[/
        return med(:rbrack) if match /\]/
        return ini(:rarrow) if match %r(=>)

        # case
        return ini(:case) if match /case\b/i
        return med(:end)  if match /end\b/i
        return ini(:then) if match /then\b/i
        return ini(:when) if match /when\b/i
        return ini(:else) if match /else\b/i

        # literals and operators
        return med(:logical, m.downcase == 'true') if match /(?:true|false)\b/i
        return med(:numeric, cast(m)) if match /(\d+(?:\.\d+)?|\.\d+)\b/
        return med(:string, unescape!(m 1)) if match /"((?:\\.|[^\\])*?)"/
        return med(:string, unescape!(m 1)) if match /'((?:\\.|[^\\])*?)'/
        return ini(:minus) if initial? && match(/-/)
        return ini(:exponential, m) if match /[*][*]|\^/
        return ini(:additive, m) if match /[+-]/
        return ini(:range) if match /[.][.]/
        return med(:dot)   if match /[.]/
        return ini(:multiplicative, m) if match %r([*/%])


        # infix ops
        return ini(:comparator, m.to_sym) if match /<=|>=|!=|<>|<|>|==|=/
        return ini(:combinator, m.downcase.to_sym) if match /(and|or)\b/i

        # general identifiers
        return med(:binder, m(1)) if match /[?]([[:alnum:]][[:alnum:]_:]*)\b/
        return med(:key, m(1)) if match /([[:alnum:]_]+\b):(?![[:alnum:]])/
        return med(:identifier, m.downcase) if match /[[:alnum:]_:]+\b/

        return ini(:error, "unbalanced quote") if match /['"]/

        match /./
        return ini(:error, "Unknown token starting with `#{(m + scanner.peek(2))}'")
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
        matched = @scanner.scan(regexp)
        return false unless matched

        # keep track of the character index independently of the byte index
        @index += matched.size

        newlines = matched.count("\n")
        @lineno += newlines
        if newlines > 0
          @colno = find_colno(matched[0])
        else
          @colno += find_colno(matched[0])
        end

        true
      end

      def location
        Location.new(@scanner.pos, @index, @lineno, @colno)
      end
    end
  end
end
