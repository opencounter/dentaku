require_relative '../function'

Dentaku::AST::Function.register("round(:numeric, :numeric) = :numeric", ->(numeric, places) {
  numeric.round(places)
})
