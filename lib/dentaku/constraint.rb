module Dentaku
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

    def &(other_contraint)
      Constraint.new(@rhs, other_contraint.rhs, Reason.conjunction(self, other_contraint))
    end

    def swap
      Constraint.new(@rhs, @lhs, @reason)
    end

    def inspect
      "<Constraint #{repr}>"
    end

    def repr
      "#{lhs.repr} = #{rhs.repr}"
    end
  end
end
