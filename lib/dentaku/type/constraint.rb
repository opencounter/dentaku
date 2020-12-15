module Dentaku
  module Type
    class Constraint
      attr_reader :lhs, :rhs, :reason

      def initialize(lhs, rhs, reason)
        @lhs = lhs
        @rhs = rhs

        raise TypeError.new("cannot constrain using var node #{@lhs.repr}!") if @lhs.var?
        raise TypeError.new("cannot constrain using var node #{@rhs.repr}!") if @rhs.var?

        @reason = reason
      end

      def map_lhs(&blk)
        Constraint.new(blk.call(@lhs), @rhs, @reason)
      end

      def map_rhs(&blk)
        Constraint.new(@lhs, blk.call(@rhs), @reason)
      end

      def &(other_constraint)
        Constraint.new(@rhs, other_constraint.rhs, Reason.conjunction(self, other_constraint))
      end

      def swap
        Constraint.new(@rhs, @lhs, @reason)
      end

      def ast_nodes
        reason.ast_nodes
      end

      def inspect
        "<Constraint #{repr}>"
      end

      def repr
        "#{lhs.repr} = #{rhs.repr}"
      end

      def repr_with_reason(depth=0)
        return repr if depth > 5 or @reason.identifier? or @reason.literal?
        if depth == 0
          "#{repr}, because: #{@reason.repr(depth)}"
        else
          "#{repr} (#{@reason.repr(depth)})"
        end
      end

      def to_sexpr
        [lhs.to_sexpr, rhs.to_sexpr, reason.to_sexpr]
      end
    end
  end
end
