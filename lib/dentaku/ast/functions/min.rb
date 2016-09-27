require_relative '../function'

Dentaku::AST::Function.register("min([:numeric]) = :numeric", ->(*args) {
  args.min
})
