require_relative '../exceptions'

module Dentaku
  module AST
    class Identifier < Node
      attr_reader :identifier

      def initialize(token)
        @identifier = token.value.to_s.downcase
      end

      def value
        context = Calculator.current.memory
        p :context => context,
          :identifier => identifier
        v = context[identifier]
        case v
        when Node
          v.evaluate
        when NilClass
          raise UnboundVariableError.new([identifier])
        else
          v
        end
      end

      def dependencies(context={})
        context.has_key?(identifier) ? dependencies_of(context[identifier]) : [identifier]
      end

      def generate_constraints(context)
        type = context.resolve_identifier(self)
        context.add_constraint!([:syntax, self], type, Type::Reason.identifier(self))
      end

      def repr
        @identifier
      end

      private

      def dependencies_of(node)
        node.respond_to?(:dependencies) ? node.dependencies : []
      end
    end
  end
end
