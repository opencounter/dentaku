module Dentaku
  module Type
    class Error < StandardError
      def locations
        raise 'abstract'
        return []
      end

      def as_json(*)
        {
          error_type: self.class.name.split(':').last,
          message: message,
          locations: locations,
          **additional_json
        }
      end

      def additional_json
        {}
      end
    end

    class InvalidAST < Error
      attr_reader :ast, :type_solution
      def initialize(ast, type_solution)
        @ast = ast
        @type_solution = type_solution
      end

      def locations
        [@ast.loc_range]
      end

      def type
        @type ||= type_solution.resolved_type_of(ast)
      end

      def additional_json
        { ast: @ast,
          type: type }
      end
    end

    class EmptyExpression < InvalidAST
      def message
        "EmptyExpression"
      end
    end

    class UnboundIdentifier < InvalidAST
      def message
        "UnboundIdentifier `#{ast.repr}' of type #{type.repr}"
      end
    end

    class UndefinedFunction < InvalidAST
      def arg_types
        @ast.args.map(&@type_solution.method(:resolved_type_of))
      end

      def message
        args_repr = arg_types.map(&:repr).join(', ')
        "UndefinedFunction #{ast.function_name}(#{args_repr}) = #{type.repr}"
      end
    end

    class FunctionAsIdentifier < InvalidAST
      def message
        "FunctionAsIdentifier `#{ast.repr}' is a function and must be called with parentheses"
      end
    end

    class WrongNumberOfArguments < InvalidAST
      def message
        "WrongNumberOfArguments for #{ast.function_name}(...): expected #{ast.arity}, got #{ast.args.size}"
      end

      def additional_json
        super.merge(
          expected: ast.arity,
          got: ast.args.size
        )
      end
    end

    module HasConstraint
      def locations
        @locations ||= extract_ranges(@constraint.ast_nodes)
      end

      def extract_ranges(causes)
        causes.map do |cause|
          case cause
          when Array then cause.flat_map(&method(:extract_ranges))
          when Token, AST::Node then cause.loc_range
          end
        end
      end
    end

    class StructError < Error
      include HasConstraint

      attr_reader :constraint
      def initialize(constraint)
        @constraint = constraint
        raise "invalid StructError" unless @constraint.rhs.key_of?
        raise "invalid StructError" unless @constraint.rhs.expr.struct?
      end

      def missing_key
        @constraint.rhs.key
      end

      def available_keys
        @constraint.rhs.expr.keys
      end

      def additional_json
        { constraint: @constraint.to_sexpr }
      end

      def message
        missing = ".#{missing_key}"
        available = available_keys.map { |k| ".#{k}" }

        available_sentence = case available.size
        when 0 then "empty struct"
        when 1 then "only available key is #{available[0]}"
        when 2 then "available keys are #{available[0]} and #{available[1]}"
        else
          available[-1] = "and #{available[-1]}"
          "available keys are #{available.join(', ')}"
        end

        available[-1] = "and #{available[-1]}" if available.size
        "StructError: Could not look up #{missing} - #{available_sentence}. Caused by #{@constraint.repr_with_reason}"
      end
    end

    class TypeMismatch < Error
      include HasConstraint

      attr_reader :constraint
      def initialize(constraint)
        @constraint = constraint
      end

      def message
        "TypeMismatch #{@constraint.repr_with_reason}"
      end

      def additional_json
        { constraint: @constraint.to_sexpr }
      end
    end

    # @ast should be an instance of AST::Invalid. Only used by
    # AST::Invalid#generate_constraints
    class ParseError < InvalidAST
      def message
        @ast.message
      end
    end

    class ErrorSet < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
      end

      def message
        "Type errors:\n#{@errors.map(&:message).join("\n")}"
      end

      def inspect
        "#<#{self.class.name} #{@errors.map(&:message).join('; ')}>"
      end
    end
  end
end
