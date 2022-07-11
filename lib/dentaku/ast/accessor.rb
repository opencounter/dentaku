module Dentaku
  module AST
    class Accessor < Node
      def initialize(expr, accessor)
        @expr = expr
        @accessor = accessor
      end

      def children
        [@expr]
      end

      def value
        struct = @expr.evaluate

        struct[@accessor]
      end

      def generate_constraints(context)
        @expr.generate_constraints(context)
        lookup = Type::Expression.key_of(Type::Expression.syntax(@expr), @accessor)
        context.add_constraint!([:syntax, self],
                                lookup,
                                [:accessor, @expr, @accessor])
      end

      def repr
        "(#{@expr.repr}.#{@accessor})"
      end
    end
  end
end
