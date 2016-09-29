module Dentaku
  module AST
    class Node
      # type annotation to be added later
      # by the type checker
      attr_accessor :type

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
        raise "Abstract #{self.class.name}"
      end

      def repr
        raise "Abstract #{self.class.name}"
      end

      def inspect
        "<AST #{repr}>"
      end

      def evaluate
        value
      end

      protected

      def value
        raise 'abstract'
      end

    end
  end
end
