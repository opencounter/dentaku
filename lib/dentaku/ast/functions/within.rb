require_relative '../function'

Dentaku::AST::Function.register("within(:range, :numeric) = :bool", ->(range, number) {
  range.include?(number)
})
