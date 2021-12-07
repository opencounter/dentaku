module Dentaku
  module Syntax
    module Matcher
      class MatchFail < Exception
      end

      class Base
        def match_vars(skel)
          return enum_for(:test, skel).to_a
        rescue MatchFail
          nil
        end

        def test(skel, &b)
          raise "abstract!"
        end

        def ~@
          Capture.new(self)
        end

        def inspect
          "match:#{repr}"
        end

      protected
        def fail!
          raise MatchFail.new
        end

        def matches?(skel, &b)
          out = []
          test(skel) { |x| out << x }
        rescue MatchFail
          return false
        else
          out.each { |x| b.call(x) }
          true
        end

        def singleton(s)
          return s unless s.is_a?(Array)
          fail! unless s.size == 1
          s[0]
        end

        def multi(s)
          return s if s.is_a?(Array)
          [s]
        end
      end

      class TokenType < Base
        def repr
          "token(#{@type.inspect})"
        end

        def initialize(type)
          @type = type.to_sym
        end

        def test(skel, &b)
          skel = singleton(skel)

          fail! unless skel.is_a?(Skeleton::Token)
          fail! unless skel.token?(@type)
        end
      end

      class Capture < Base
        def repr
          "~#{@matcher.repr}"
        end

        def initialize(matcher)
          @matcher = matcher
        end

        def test(skel, &b)
          fail! unless @matcher.matches?(skel, &b)
          yield skel
        end
      end

      class Ignore < Base
        def repr
          '_'
        end

        def test(skel, &b)
          # pass
        end
      end

      class NonEmpty < Base
        def repr
          'nonempty'
        end

        def test(skel, &b)
          fail! if multi(skel).empty?
        end
      end

      class Nested < Base
        def initialize(open_type, matcher)
          @open_type = open_type
          @matcher = matcher
        end

        def repr
          "nested(#{open_type}, #{matcher.repr})"
        end

        def test(skel, &b)
          skel = singleton(skel)
          fail! unless skel.nested?(@open_type)
          fail! unless @matcher.matches?(skel.elems, &b)
        end
      end

      class IsError < Base
        def repr
          "error"
        end

        def test(skel, &b)
          fail! unless singleton(skel).error?
        end
      end

      class Split < Base
        def initialize(split, before, after)
          @split = split
          @before = before
          @after = after
        end
      end

      class LSplit < Split
        def repr
          "lsplit(#{@split.repr}, #{@before.repr}, #{@after.repr})"
        end

        def test(skel, &b)
          list = multi(skel)

          matched = nil
          list.each_with_index do |elem, index|
            next unless @split.matches?(elem, &b)
            matched = index
            break
          end

          fail! unless matched
          before = list[0...matched]
          after = list[(matched+1)..-1]

          fail! unless @before.matches?(before, &b)
          fail! unless @after.matches?(after, &b)
        end
      end

      class RSplit < Split
        def repr
          "rsplit(#{@split.repr}, #{@before.repr}, #{@after.repr})"
        end

        def test(skel, &b)
          list = multi(skel)

          matched = nil
          index = list.size
          list.reverse_each do |elem|
            index -= 1
            next unless @split.matches?(elem, &b)
            matched = index
            break
          end

          fail! if matched.nil?
          before = list[0...matched]
          after = list[(matched+1)..-1]

          fail! unless @before.matches?(before, &b)
          fail! unless @after.matches?(after, &b)
        end
      end

      class Starts < Base
        def initialize(first, rest)
          @first, @rest = first, rest
        end

        def test(skel, &b)
          skel = multi(skel)
          fail! if skel.empty?
          first, rest = skel.first, skel[1..]
          fail! unless @first.matches?(first, &b)
          fail! unless @rest.matches?(rest, &b)
        end
      end

      class Ends < Base
        def initialize(last, pre)
          @pre, @last = pre, last
        end

        def test(skel, &b)
          skel = multi(skel)
          fail! if skel.empty?
          pre, last = skel[0...-1], skel.last
          fail! unless @last.matches?(last, &b)
          fail! unless @pre.matches?(pre, &b)
        end
      end

      class Exactly < Base
        def repr
          "exactly(#{@matchers.map(&:repr).join(', ')})"
        end

        def initialize(matchers)
          @matchers = matchers
        end

        def test(skel, &b)
          list = multi(skel)
          fail! unless list.size == @matchers.size

          @matchers.zip(list) do |matcher, el|
            fail! unless matcher.matches?(el, &b)
          end
        end
      end

      class Empty < Base
        def test(skel, &b)
          ls = multi(skel)
          fail! unless ls.empty?
        end
      end

      module DSL
        def match(skel, matcher, &b)
          vars = matcher.match_vars(skel)

          # no match
          return false if vars.nil?

          b.call(*vars)

          true
        end

        def token(type)
          @__tokens ||= {}
          @__tokens[type] ||= TokenType.new(type)
        end

        def nested(type, matcher=nil)
          matcher ||= _
          Nested.new(type, matcher)
        end

        def empty
          @__empty ||= Empty.new
        end

        def lsplit(split, before, after)
          LSplit.new(split, before, after)
        end

        def rsplit(before, split, after)
          RSplit.new(before, split, after)
        end

        def starts(elem, rest)
          Starts.new(elem, rest)
        end

        def ends(elem, rest)
          Ends.new(elem, rest)
        end

        def exactly(*matchers)
          Exactly.new(matchers)
        end

        def _
          ignore
        end

        def __
          nonempty
        end

        def capture(matcher)
          ~matcher
        end

        def nonempty
          @__nonempty ||= NonEmpty.new
        end

        def ignore
          @__ignore ||= Ignore.new
        end

        def error
          @__error ||= IsError.new
        end
      end
    end
  end
end
