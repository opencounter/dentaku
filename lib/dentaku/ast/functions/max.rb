require 'dentaku/ast/function'

Dentaku::AST::Function.register("max([:numeric]) = :numeric", ->(args) {
  args.max
})
