require 'dentaku/exceptions'

module Dentaku
  module AST
    class Identifier < Node
      attr_reader :identifier

      def serialized_values
        [identifier]
      end

      def is_function_name?
        Function.registry.keys.include?(@identifier)
      end

      def initialize(name)
        @identifier = name.to_s.downcase
      end

      def value
        value = context[identifier]
        case value
        when Node
          value.evaluate
        when nil
          if !Calculator.current.partial_eval?
            Calculator.current.trace(:unsatisfied, identifier)
          end

          raise UnboundVariableError.new(self, [identifier])
        else
          Calculator.current.trace(:satisfied, identifier)
          value
        end
      end

      def each_identifier
        yield @identifier
      end

      def generate_constraints(context)
        if is_function_name?
          return context.invalid_ast!(Type::FunctionAsIdentifier, self)
        end

        type = context.resolve_identifier(self)
        context.add_constraint!([:syntax, self], type, Type::Reason.identifier(self))
      end

      def repr
        @identifier
      end
    end
  end
end
