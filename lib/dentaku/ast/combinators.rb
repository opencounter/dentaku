require_relative './operation'

module Dentaku
  module AST
    class Combinator < Operation
      def types
        [:bool, :bool, :bool]
      end
    end

    class And < Combinator
      def value
        left.evaluate && right.evaluate
      end

      def repr
        "(#{left.repr} AND #{right.repr})"
      end
    end

    class Or < Combinator
      def value
        left.evaluate || right.evaluate
      end

      def repr
        "(#{left.repr} OR #{right.repr})"
      end

      def simplified_value

        potentially_true_children = children.reject {|c| c.children.empty? && !c.value}

        if potentially_true_children.any? {|c| c.children.empty? && c.value }
          make_literal(true)
        else
          case potentially_true_children.length
          when 0 then make_literal(false)
          when 1 then potentially_true_children.first
          when 2 then self
          end
        end

      end
    end
  end
end
