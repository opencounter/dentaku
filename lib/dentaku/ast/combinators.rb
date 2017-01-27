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

      def simplified_value
        literal, unliteral = children.partition(&:literal?)

        if literal.any? {|l| !l.value}
          make_literal(false)
        else
          case unliteral.length
          when 0 then make_literal(true)
          when 1 then unliteral.first
          when 2 then self
          end
        end
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
        literal, unliteral = children.partition(&:literal?)

        if literal.any?(&:value)
          make_literal(true)
        else
          case unliteral.length
          when 0 then make_literal(false)
          when 1 then unliteral.first
          when 2 then self
          end
        end
      end
    end
  end
end
