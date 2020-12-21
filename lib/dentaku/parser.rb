require_relative 'ast'

module Dentaku
  class ParseError < StandardError
    attr_reader :message, :location

    def initialize(message, *causes)
      @message = message
      @location = extract_range(causes)
    end

    def inspect
      "<ParseError #{@message}@#{@location}>"
    end

    private

    def extract_range(causes)
      return [[0,0], [0,0]] if causes.empty?

      locations = causes.map do |cause|
        case cause
        when Array then cause
        when Token, AST::Node then cause.loc_range
        end
      end
      start_points = locations.map(&:first)
      end_points = locations.map(&:last)
      [start_points.sort.first, end_points.sort.last]
    end
  end

  class Parser
    attr_reader :input, :output, :operations, :arities

    def initialize(tokens, options={})
      @input      = tokens.dup
      @output     = []
      @operations = []
      @arities    = []
      @debug = options[:debug]
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
      consume(end_token) while check_op(AST::Operation)
    end

    def consume(end_token, count=nil)
      operator_class, begin_token = operations.pop

      args = get_args(count || operator_class.arity || 2)

      if operator_class.arity && (args.length != operator_class.arity || args.any?(&:nil?))
        raise ParseError.new(
          "Wrong number of args for #{operator_class.inspect} expected #{operator_class.arity}, got #{args.compact.length}",
          begin_token, end_token
        )
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

      debug do
        puts 'TOKENS:'
        input.each { |i| p i }
      end

      while true
        token, last_token = input.shift, token
        break unless token

        debug do
          puts "remaining: #{input.map(&:value).join(", ")}"

          puts 'operations:'
          operations.reverse.each { |o| p o }

          puts 'output:'
          output.reverse.each { |o| p o }

          puts "arities: #{arities.reverse.each { |a| a }.join(", ")}"
          puts "\ncurrent: #{token}"
        end

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
          raise ParseError.new("Invalid use of function #{token}", token) unless AST::Identifier.valid?(token)
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
              raise ParseError.new("Expected case token, got #{ token.inspect }", token)
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
                raise ParseError.new("Case missing switch variable", last_token)
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
            raise ParseError.new("Expected case token, got #{ token.inspect }", token)
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
            raise ParseError.new("Unexpected token in parenthesis", last_token) unless grouping == AST::Grouping

            if check_op(AST::Function)
              consume(token, arities.pop.succ)
            end

          when :comma
            arities[-1] += 1
            consume_infix(last_token)

          else
            raise ParseError.new("Unknown grouping token #{ token.value }", token)
          end

        when :dictionary
          case token.value
          when :open
              operations.push [AST::Dictionary, token]
              arities.push 0

          when :close
            consume_infix(last_token)
            consume(token, arities.pop + 2)

          when :comma
            arities[-1] += 2
            consume_infix(last_token)
          else
            raise ParseError.new("Unknown dictionary token #{ token.value }", token)
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
            raise ParseError.new("Unknown list token #{ token }", token)
          end
        else
          raise ParseError.new("Unknown token #{ token }", token)
        end
      end

      debug do
        puts
        puts 'PARSED INPUT'
        puts 'operations:'
        operations.reverse.each { |o| p o }

        puts 'output:'
        output.reverse.each { |o| p o }

        puts 'arities:'
        arities.reverse.each { |a| p a }
      end

      while operations.any?
        consume(last_token)
      end

      unless output.count == 1
        raise ParseError.new("Unexpected output #{output.length}", output[1])
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

    def debug
      yield if @debug
    end
  end
end
