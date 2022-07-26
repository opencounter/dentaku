module Dentaku
  module Syntax
    module Skeleton
      class Base
        def root?(*)   false; end

        def nested?(*) false; end

        # TODO - clause should be deprecated, but is still in use elsewhere.
        def clause?(*) false; end

        def atom?(*) false; end

        def error?(*) false; end

        def first_token
          raise "abstract"
        end

        def last_token
          raise "abstract"
        end

        def inspect
          "<skeleton #{repr}>"
        end
      end

      class Nested < Base
        def nested?(open_type)
          @open.category == open_type
        end

        attr_reader :open, :close, :elems
        def initialize(open, close, elems)
          @open = open
          @close = close
          @elems = elems
        end

        def first_token
          @open
        end

        def last_token
          @close
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

        def first_token
          @elems.first
        end

        def last_token
          @elems.last
        end

        def repr
          "{root #{@elems.map(&:repr).join(' ')}}"
        end
      end

      class Atom < Base
        attr_reader :tok
        def initialize(tok)
          @tok = tok
        end

        def first_token
          @tok
        end

        def last_token
          @tok
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

        def atom?(category=nil)
          category.nil? || @tok.category == category
        end

        def repr
          if @tok.value.nil?
            "{atom #{@tok.category}}"
          else
            "{atom #{@tok.category}(#{@tok.value.inspect})}"
          end
        end
      end

      class Error < Base
        def error?(*) true end

        attr_reader :tokens, :message
        def loc_range
          Tokenizer::LocRange.between(@tokens.first, @tokens.last)
        end

        def initialize(tokens, message)
          raise "bad error handling" if tokens.empty?

          @tokens = tokens
          @message = message
        end

        def first_token
          @tokens.first
        end

        def last_token
          @tokens.last
        end

        def repr
          "{@ERR:#{@message.inspect} [#{@tokens.map(&:repr).join(' ')}]}"
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

        def unexpected_close_message
          if @expected_close
            expected_desc = Dentaku::Token::DESC[@expected_close]
            expected_desc ||= @expected_close.to_s

            "mismatched nesting: expected #{expected_desc}, got #{@token.desc}"
          else
            "extraneous closing #{@token.desc}"
          end
        end

        def parse(tokens)
          @last = nil
          @token = nil

          loop do
            @last = @token
            @token = tokens.next
            break if @token.is?(:eof)

            if @token.is?(:error)
              @elems << Error.new([@token], @token.value)
            elsif @expected_close && @token.is?(@expected_close)
              return Nested.new(@open, @token, @elems)
            elsif @token.close?
              return Error.new([@token], unexpected_close_message)
            elsif @token.nest?
              result = Parser.new(@token, @token.nest_pair).parse(tokens)
              return result if result.error?
              @elems << result
            else
              @elems << Atom.new(@token)
            end
          end

          if @open.nil?
            return Root.new(@elems)
          else
            return Error.new([@open], "unclosed #{@open.desc}")
          end
        end
      end
    end
  end
end
