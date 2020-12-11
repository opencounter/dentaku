require_relative '../function'

module Dentaku
  class Pair
    attr_reader :l, :r
    def initialize(l, r) @l = l; @r = r end
    def inspect
      "pair(#{l.inspect}, #{r.inspect})"
    end
  end
end

Dentaku::AST::Function.register('pair(%a, %b) = :pair(%a %b)', ->(a, b) { Dentaku::Pair.new(a, b) })
Dentaku::AST::Function.register('left(:pair(%a, %b)) = %a', ->(t) { t.l })
Dentaku::AST::Function.register('right(:pair(%a, %b)) = %b', ->(t) { t.r })
