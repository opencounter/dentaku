require_relative '../function'

Dentaku::AST::Function.register("not(:bool) = :bool", ->(logical) {
  ! logical
})
