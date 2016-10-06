require 'strscan'

module Dentaku
  module Type
    module Syntax
      def self.parse_spec(string)
        Parser.parse_spec(Token.tokenize(string))
      end

      def self.parse_type(string)
        Parser.parse_type(Token.tokenize(string))
      end

      class Token
        attr_reader :name, :value
        def initialize(name, value=nil)
          @name = name
          @value = value
        end

        def inspect
          if @value
            ":#{@name}(#{@value})"
          else
            ":#{@name}"
          end
        end

        def self.tokenize(string, &b)
          return enum_for(:tokenize, string) unless block_given?

          string = ":#{string}" if string.is_a?(Symbol)

          scanner = StringScanner.new(string)

          until scanner.eos?
            if scanner.scan /[=]/
              yield new(:EQ)
            elsif scanner.scan /[(]/
              yield new(:LPAREN)
            elsif scanner.scan /[)]/
              yield new(:RPAREN)
            elsif scanner.scan /\[/
              yield new(:LBRACE)
            elsif scanner.scan /\]/
              yield new(:RBRACE)
            elsif scanner.scan /%(\w+)/
              yield new(:VAR, scanner[1])
            elsif scanner.scan /:(\w+)/
              yield new(:PARAM, scanner[1])
            elsif scanner.scan /\w+/
              yield new(:NAME, scanner[0])
            elsif scanner.scan /[\s,]+/
              # pass
            else
              raise "invalid thing!"
            end
          end

          yield new(:EOF)
        end
      end

      class TypeSpec
        attr_reader :name, :arg_types, :return_type
        def initialize(name, arg_types, return_type)
          @name = name
          @arg_types = arg_types
          @return_type = return_type
        end
      end

      class Parser
        def self.parse_spec(tokens)
          new(tokens).parse_spec
        end

        def self.parse_type(tokens)
          new(tokens).parse_type
        end

        def initialize(tokens)
          @tokens = tokens
          @head = @tokens.next
        end

        def parse_type
          result = parse_type_inner
          expect(:EOF)
          result
        end

        def parse_spec
          function_name = expect!(:NAME)
          expect!(:LPAREN)
          arg_types = parse_types(:RPAREN)
          expect!(:EQ)
          return_type = parse_type_inner
          expect(:EOF)

          TypeSpec.new(function_name, arg_types, return_type)
        end

        private
        def next!
          @head = @tokens.next
        end

        def check(toktype)
          return @head.name == toktype
        end

        def check!(toktype)
          out = check(toktype)
          next! if out
          out
        end

        def check_val(toktype)
          return @head.value if check(toktype)
        end

        def check_val!(toktype)
          @head.value.tap { next! } if check(toktype)
        end

        def expect(toktype)
          if check(toktype)
            @head.value
          else
            raise "parse error: expected #{toktype.inspect}, got #{@head.inspect}"
          end
        end

        def expect!(toktype)
          expect(toktype).tap { next! }
        end

        def parse_type_inner
          if (name = check_val!(:VAR))
            Expression.var(name)
          elsif (param_name = check_val!(:PARAM))
            if check!(:LPAREN)
              member_types = parse_types(:RPAREN)
              Expression.param(param_name.to_sym, member_types)
            else
              Expression.concrete(param_name.to_sym)
            end
          elsif check!(:LBRACE)
            list_type = parse_type_inner
            expect!(:RBRACE)
            Expression.param(:list, [list_type])
          else
            raise "invalid type expression starting with #{@head.inspect}"
          end
        end

        def parse_types(expected_end)
          arg_types = []
          until check(expected_end)
            arg_types << parse_type_inner
          end
          expect!(expected_end)

          arg_types
        end
      end
    end
  end
end
