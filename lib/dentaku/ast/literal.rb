module Dentaku
  module AST
    class Literal < Node
      def initialize(value)
        @value = value
      end

      def value
        @value
      end

      def dependencies(*)
        []
      end

      def generate_constraints(context)
        context.add_constraint!([:syntax, self], [:concrete, value_type], [:literal, self])
      end

      def value_type
        raise "Abstract #{self.class.name}"
      end

      def repr
        @value.inspect
      end

      def cachable?
        false
      end
    end
  end
end
