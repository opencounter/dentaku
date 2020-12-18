require_relative '../exceptions'

module Dentaku
  module AST
    class Identifier < Node
      attr_reader :identifier

      def self.valid?(token)
        !Function.registry.keys.include?(token.value)
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

      def value_with_trace(trace, &default_blk)
        v, type = context[identifier]
        case v
        when Node
          v.evaluate
        when NilClass
          trace.unsatisfied(identifier)

          if default_blk
            default_blk.call
          else
            raise UnboundVariableError.new([identifier])
          end
        else
          if type == :default
            trace.unsatisfied(identifier)
          else
            trace.satisfied(identifier)
          end
          v
        end
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
