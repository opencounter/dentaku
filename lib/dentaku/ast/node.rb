module Dentaku
  module AST
    class Node
      def self.precedence
        0
      end

      def self.arity
        nil
      end

      def dependencies(context={})
        []
      end

      def constraints(context)
        generate_constraints(context)
        context.constraints
      end

      def generate_constraints(context)
        raise 'Abstract'
      end

      def pretty_print
        raise "Abstract #{self.class.name}"
      end

      def inspect
        "<AST #{pretty_print}>"
      end
    end
  end
end
