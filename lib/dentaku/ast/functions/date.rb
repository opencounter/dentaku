require 'date'

Dentaku::AST::Function.register(
  'parse_date(:numeric, :numeric, :numeric) = :numeric', ->(*args) {
    Date.new(*args).to_time.to_i
  }
)
