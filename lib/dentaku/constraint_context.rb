require 'dentaku/type_expression'
require 'dentaku/reason'

module Dentaku
  class ConstraintContext
    class UnboundIdentifier < StandardError
      def initialize(identifier)
        @identifier = identifier
      end

      def message
        "UnboundIdentifier (#{@identifier})"
      end
    end

    attr_reader :constraints

    def initialize(&resolver)
      @constraints = []
      @resolver = resolver
    end

    def resolve_identifier(identifier)
      type = @resolver.call(identifier)
      type or raise UnboundIdentifier.new(identifier)
      TypeExpression.from_sexpr(type)
    end

    def add_constraint!(lhs, rhs, reason)
      @constraints << Constraint.new(
        TypeExpression.from_sexpr(lhs),
        TypeExpression.from_sexpr(rhs),
        [Reason.from_sexpr(reason)]
      )
    end
  end

  class StaticConstraintContext < ConstraintContext
    def initialize(map)
      string_map = {}
      map.each { |k, v| string_map[k.to_s] = v }

      block = lambda { |node| string_map[node.identifier] }
      super(&block)
    end
  end
end
