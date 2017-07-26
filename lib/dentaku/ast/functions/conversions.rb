Dentaku::AST::Function.register('to_int(:string) = :numeric', ->(str) {
  str.to_i
})

Dentaku::AST::Function.register('to_str(:numeric) = :string', ->(str) {
  str.to_s
})
