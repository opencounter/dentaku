module Dentaku
  module Syntax
    module Skeleton
      class Base
        def root?(*)   false; end
        def nested?(*) false; end
        def clause?(*) false; end
        def token?(*)  false; end

        def match(matcher, &b)
          vars = matcher.match_vars(self)
          return false unless vars
          yield *vars
          true
        end

        def inspect
          "<skeleton #{repr}>"
        end
      end

      class Nested < Base
        def nested?(*) true; end

        attr_reader :open, :close, :elems
        def initialize(open, close, elems)
          @open = open
          @close = close
          @elems = elems
        end

        def loc_range
          Tokenizer::LocRange.between(@open, @close)
        end

        def repr
          "{nested #{open.category} #{elems.map(&:repr).join(' ')}}"
        end
      end

      class Root < Base
        def root?(*) true; end

        attr_reader :elems
        def initialize(elems)
          @elems = elems
        end

        def repr
          "{root #{@elems.map(&:repr).join(' ')}}"
        end
      end

      class Token < Base
        attr_reader :tok
        def initialize(tok)
          @tok = tok
        end

        def clause?
          @tok.clause?
        end

        def value
          @tok.value
        end

        def loc_range
          @tok.loc_range
        end

        def token?(category=nil)
          category.nil? || @tok.category == category
        end

        def repr
          if @tok.value.nil?
            "{token #{@tok.category}}"
          else
            "{token #{@tok.category}(#{@tok.value.inspect})}"
          end
        end
      end

      def self.parse(tokens)
        Skeleton::Parser.parse(tokens)
      end

      class Parser
        def self.parse(tokens)
          new(nil, nil).parse(tokens.each)
        end

        def initialize(open, expected_close)
          @open = open
          @expected_close = expected_close
          @elems = []
        end

        def parse(tokens)
          @last = nil
          @token = nil

          loop do
            @last = @token
            @token = tokens.next
            break if @token.is?(:eof)
            # p :skel => [@last, @token, @elems]

            if @expected_close && @token.is?(@expected_close)
              return Nested.new(@open, @token, @elems)
            elsif @token.nest?
              @elems << Parser.new(@token, @token.nest_pair).parse(tokens)
            else
              @elems << Token.new(@token)
            end
          end

          if @open.nil?
            return Root.new(@elems)
          else
            error!(@token, "Unmatched nesting, expected #{@expected_close}")
          end
        end
      end
    end
  end
end
