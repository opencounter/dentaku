require_relative './ast'

# string -> tokenize/lexing (tokens) -> parse (AST)
# typecheck(AST, resolve_types)
# ast.value(deps)

module Dentaku
  class ParseError < StandardError
  end

  class Parser
    attr_reader :input, :output, :operations, :arities

    def initialize(tokens, options={})
      @input      = tokens.dup
      @output     = []
      @operations = options.fetch(:operations, [])
      @arities    = options.fetch(:arities, [])
    end

    # AST Plus ( 1, AST * 5, 6)

    def get_args(count)
      Array.new(count) { output.pop }.reverse
    end

    def get_op(index=-1)
      el = operations[index]
      return nil unless el
      el[0]
    end

    def check_op(klass, index=-1)
      op = get_op(index)
      op && op <= klass
    end

    def consume_infix(end_token)
      consume(end_token) while check_op(AST::Operation)
    end

    def consume(end_token, count=2)
      operator_class, begin_token = operations.pop
      args = get_args(operator_class.arity || count)

      if operator_class.arity && (args.length != operator_class.arity || args.any?(&:nil?))
        raise ParseError, "Wrong number of args for #{operator_class.inspect} expected #{operator_class.arity}, got #{args.compact.length}"
      end

      operator = operator_class.new(*args)
      operator.begin_token = begin_token
      operator.end_token = end_token
      output.push operator
    end

    def push_output(klass, token)
      output.push klass.new(token).tap { |ast|
        ast.begin_token = token
        ast.end_token = token
      }
    end

    def parse
      return AST::Nil.new if input.empty?
      puts 'TOKENS:'
      input.each { |i| p i }

      while true
        token, last_token = input.shift, token
        break unless token

        puts 'operations:'
        operations.reverse.each { |o| p o }

        puts 'output:'
        output.reverse.each { |o| p o }

        puts 'arities:'
        arities.reverse.each { |a| p a }

        puts '======='
        puts 'next:'
        p token

        case token.category
        when :numeric
          push_output(AST::Numeric, token)

        when :range
          push_output(AST::Range, token)

        when :logical
          push_output(AST::Logical, token)

        when :string
          push_output(AST::String, token)

        when :identifier
          raise ParseError, "Invalid use of function #{token}" unless AST::Identifier.valid?(token)
          push_output(AST::Identifier, token)

        when :key
          push_output(AST::Key, token)

        when :operator, :comparator, :combinator
          op_class = operation(token)

          while true
            break if !get_op || check_op(AST::Grouping)
            break if get_op.precedence < op_class.precedence
            break if op_class.right_associative? && op_class.precedence == get_op.precedence

            consume(last_token)
          end

          operations.push [op_class, token]

        when :function
          arities.push 0
          operations.push [function(token), token]

        when :case
          case token.value
          when :open
            operations.push [AST::Case, token]
            arities.push(0)
          when :close
            consume_infix(last_token)

            if check_op(AST::CaseThen)
              consume(last_token)

              operations.push([AST::CaseConditional, nil])
              consume(last_token, 2)
              arities[-1] += 1
            elsif check_op(AST::CaseElse)
              consume(last_token)

              arities[-1] += 1
            end

            unless check_op(AST::Case)
              raise ParseError, "Expected case token, got #{ token.inspect }"
            end
            consume(token, arities.pop + 1)
          when :when
            consume_infix(last_token)

            if check_op(AST::CaseThen)
              consume(last_token)

              operations.push([AST::CaseConditional, nil])
              consume(last_token, 2)
              arities[-1] += 1
            elsif check_op(AST::Case)
              if last_token.category == :case
                raise ParseError, "Case missing switch variable"
              end

              operations.push([AST::CaseSwitchVariable, operations.last[1]])
              consume(last_token)
            end

            operations.push([AST::CaseWhen, token])
          when :then
            consume_infix(last_token)

            if check_op(AST::CaseWhen)
              consume(last_token)
            end
            operations.push([AST::CaseThen, token])
          when :else
            consume_infix(last_token)

            if check_op(AST::CaseThen)
              consume(last_token)

              operations.push([AST::CaseConditional, nil])
              consume(last_token, 2)
              arities[-1] += 1
            end

            operations.push([AST::CaseElse, token])
          else
            raise ParseError, "Expected case token, got #{ token.inspect }"
          end

        when :grouping
          case token.value
          when :open
            if input.first && input.first.value == :close
              consume(input.shift, 0)
            else
              operations.push [AST::Grouping, token]
            end

          when :close
            consume_infix(last_token)

            grouping, lparen = operations.pop
            raise ParseError, "Unexpected token in parenthesis" unless grouping == AST::Grouping

            if check_op(AST::Function)
              consume(token, arities.pop.succ)
            end

          when :comma
            arities[-1] += 1
            consume_infix(last_token)

          else
            raise ParseError, "Unknown grouping token #{ token.value }"
          end

        when :dictionary
          case token.value
          when :open
            operations.push [AST::Dictionary, token]

          when :close
            consume_infix(last_token)
            consume(token, output.length)

          when :comma
            consume_infix(last_token)

          else
            raise ParseError, "Unknown dictionary token #{ token.value }"
          end
        when :list
          case token.value
          when :open
            operations.push [AST::List, token]
            if input.first && input.first.category == :list && input.first.value == :close
              consume(input.shift, 0)
            else
              arities.push 1
            end

          when :close
            consume_infix(last_token)
            consume(token, arities.pop)

          when :comma
            arities[-1] += 1 unless arities.empty?

            consume_infix(last_token)
          else
            raise ParseError, "Unknown list token #{ token }"
          end
        else
          raise ParseError, "Unknown token #{ token }"
        end
      end

      if op = operations.detect { |op| op[0] == Dentaku::AST::Case }
        raise ParseError, "Missing CASE END"
      end

      # puts
      # puts 'PARSED INPUT'
      # puts 'operations:'
      # operations.reverse.each { |o| p o }

      # puts 'output:'
      # output.reverse.each { |o| p o }

      # puts 'arities:'
      # arities.reverse.each { |a| p a }

      while operations.any?
        consume(last_token)
      end

      unless output.count == 1
        raise ParseError, "Unexpected output #{output.length}"
      end

      output.first
    end

    def operation(token)
      {
        add:      AST::Addition,
        subtract: AST::Subtraction,
        multiply: AST::Multiplication,
        divide:   AST::Division,
        pow:      AST::Exponentiation,
        negate:   AST::Negation,
        mod:      AST::Modulo,

        lt:       AST::LessThan,
        gt:       AST::GreaterThan,
        le:       AST::LessThanOrEqual,
        ge:       AST::GreaterThanOrEqual,
        ne:       AST::NotEqual,
        eq:       AST::Equal,

        and:      AST::And,
        or:       AST::Or,
      }.fetch(token.value)
    end

    def function(token)
      Dentaku::AST::Function.get(token.value)
    end
  end
end
