module Dentaku
  module AST
    class Node
      # type annotation to be added later
      # by the type checker
      attr_accessor :type
      attr_accessor :begin_token
      attr_accessor :end_token

      def self.precedence
        0
      end

      def self.arity
        arity = instance_method(:initialize).arity
        arity < 0 ? nil : arity
      end

      def dependencies(context={})
        []
      end

      def constraints(context)
        generate_constraints(context)
        context.constraints
      end

      def loc_range
        return [] unless begin_token && end_token
        [begin_token.begin_location, end_token.end_location]
      end

      def generate_constraints(context)
        raise "Abstract #{self.class.name}"
      end

      def children
        []
      end

      def each
        return enum_for(:each) unless block_given?

        yield self

        children.each do |child|
          child.each do |c|
            yield c
          end
        end
      end

      def leaves
        each.select { |c| c.children.empty? }
      end

      def repr
        "(TODO #{self.class.name})"
      end

      def inspect
        "<AST #{repr}>"
      end

      def evaluate
        Calculator.current.trace(self) do
          value
        end
      end

      def simplify
        simplified_children = children.map(&:simplify)
        simplified_me = self.class.new(*simplified_children)
        simplified_me.simplified_value
      end

      protected

      def value
        raise 'abstract'
      end

      def simplified_value
        begin
          make_literal(self.value)
        rescue UnboundVariableError
          self
        end
      end

      def make_literal(val)
        AST::Literal.new(Token.new( 'abstract_literal', val, loc_range ))
      end
    end
  end
end
