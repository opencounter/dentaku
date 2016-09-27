require_relative '../function'

Dentaku::AST::Function.register("roundup(:numeric, :numeric) = :numeric", ->(numeric, precision) {
  tens = 10.0**precision
  result = (numeric * tens).ceil / tens
  precision <= 0 ? result.to_i : result
})
