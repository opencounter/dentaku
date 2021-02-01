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

      def initialize(token)
        @identifier = token.value.to_s.downcase
      end

      def evaluate(&default_blk)
        return value unless cachable?

        Calculator.current.cache_for(self) do |cache|
          cache.trace do |tracer|
            value_with_trace(tracer, &default_blk)
          end
        end
      end

      def value_with_trace(trace)
        v, type = context[identifier]

        if v.nil? || (type == :default && Calculator.current.partial_eval?)
          trace.unsatisfied(identifier)

          raise UnboundVariableError.new([identifier])
        elsif type == :default
          trace.unsatisfied(identifier)
        else
          trace.satisfied(identifier)
        end

        v
      end

      def value
        v, type = context[identifier]
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
        if is_function_name?
          return context.invalid_ast!(Type::FunctionAsIdentifier, self)
        end

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
