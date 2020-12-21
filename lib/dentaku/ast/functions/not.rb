require 'dentaku/ast/function'

Dentaku::AST::Function.register("not(:bool) = :bool", ->(logical) {
  ! logical
})
