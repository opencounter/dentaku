require_relative './ast'

module Dentaku
  class Parser
    attr_reader :input, :output, :operations, :arities

    def initialize(tokens, options={})
      @input      = tokens.dup
      @output     = []
      @operations = options.fetch(:operations, [])
      @arities    = options.fetch(:arities, [])
    end

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
    end

    def consume(end_token, count=2)
      operator_class, begin_token = operations.pop
      operator = operator_class.new(*get_args(operator_class.arity || count))
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

      while true


        token, last_token = input.shift, token
        break unless token

        # puts 'operations:'
        # operations.reverse.each { |o| p o }

        # puts 'output:'
        # output.reverse.each { |o| p o }

        # puts '======='
        # puts 'next:'
        # p token

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
            # special handling for case nesting: strip out inner case
            # statements and parse their AST segments recursively
            if operations.map { |x| x[0] }.include?(AST::Case)
              open_cases = 0
              case_end_index = nil

              input.each_with_index do |token, index|
                if token.category == :case && token.value == :open
                  open_cases += 1
                end

                if token.category == :case && token.value == :close
                  if open_cases > 0
                    open_cases -= 1
                  else
                    case_end_index = index
                    break
                  end
                end
              end
              inner_case_inputs = input.slice!(0..case_end_index)
              subparser = Parser.new(
                inner_case_inputs,
                operations: [[AST::Case, token]],
                arities: [0]
              )
              subparser.parse
              output.concat(subparser.output)
            else
              operations.push [AST::Case, token]
              arities.push(0)
            end
          when :close
            if check_op(AST::CaseThen, 1)
              consume(last_token) until check_op(AST::Case)

              operations.push([AST::CaseConditional, token])
              consume(last_token, 2)
              arities[-1] += 1
            elsif check_op(AST::CaseElse, 1)
              consume(last_token) until check_op(AST::Case)

              arities[-1] += 1
            end

            unless operations.count == 1 && check_op(AST::Case)
              fail "Unprocessed token #{ token.value }"
            end
            consume(token, arities.pop + 1)
          when :when
            if check_op(AST::CaseThen, 1)
              consume(last_token) until check_op(AST::CaseWhen) || check_op(AST::Case)

              operations.push([AST::CaseConditional, token])
              consume(last_token, 2)
              arities[-1] += 1
            elsif check_op(AST::Case)
              operations.push([AST::CaseSwitchVariable, token])
              consume(last_token)
            end

            operations.push([AST::CaseWhen, token])
          when :then
            if check_op(AST::CaseWhen, 1)
              consume(last_token) until check_op(AST::CaseThen) || check_op(AST::Case)
            end
            operations.push([AST::CaseThen, token])
          when :else
            if check_op(AST::CaseThen, 1)
              consume(last_token) until check_op(AST::Case)

              operations.push([AST::CaseConditional, token])
              consume(last_token, 2)
              arities[-1] += 1
            end

            operations.push([AST::CaseElse, token])
          else
            fail "Unknown case token #{ token.value }"
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
            consume(last_token) until check_op(AST::Grouping)

            grouping, lparen = operations.pop
            fail "Unbalanced parenthesis" unless grouping == AST::Grouping

            if check_op(AST::Function)
              consume(token, arities.pop.succ)
            end

          when :comma
            arities[-1] += 1
            consume(last_token) until check_op(AST::Grouping)

          else
            fail "Unknown grouping token #{ token.value }"
          end

        when :dictionary
          case token.value
          when :open
            operations.push [AST::Dictionary, token]

          when :close
            consume(last_token) until check_op(AST::Dictionary)
            consume(token, output.length)

          when :comma
            consume(last_token) until check_op(AST::Dictionary)

          else
            fail "Unknown dictionary token #{ token.value }"
          end
        when :list
          case token.value
          when :open
            operations.push [AST::List, token]
            arities.push 0

          when :close
            consume(last_token) until check_op(AST::List)
            consume(token, arities.pop)

          when :comma
            arities[-1] += 1 unless arities.empty?

            consume(last_token) until check_op(AST::List)
          else
            fail "Unknown list token #{ token.value }"
          end
        else
          fail "Not implemented for tokens of category #{ token.category }"
        end
      end

      while operations.any?
        consume(last_token)
      end

      unless output.count == 1
        fail "Parse error"
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
