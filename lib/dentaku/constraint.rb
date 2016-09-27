module Dentaku
  class Constraint
    attr_reader :lhs, :rhs, :reasons

    def initialize(lhs, rhs, reasons=[])
      @lhs = lhs
      @rhs = rhs
      @reasons = reasons
    end

    def inspect
      "<Constraint #{lhs.pretty_print} = #{rhs.pretty_print}>"
    end
  end
end
