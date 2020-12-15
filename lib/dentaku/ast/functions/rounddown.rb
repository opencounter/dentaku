require 'dentaku/ast/function'

Dentaku::AST::Function.register("rounddown(:numeric, :numeric) = :numeric", ->(numeric, precision) {
  tens = 10.0**precision
  result = (numeric * tens).floor / tens
  precision <= 0 ? result.to_i : result
})
