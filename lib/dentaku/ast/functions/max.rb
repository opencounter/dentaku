require_relative '../function'

Dentaku::AST::Function.register("max([:numeric]) = :numeric", ->(*args) {
  args.max
})
