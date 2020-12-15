require 'dentaku/ast/function'

Dentaku::AST::Function.register("within(:range, :numeric) = :bool", ->(range, number) {
  range.include?(number)
})
