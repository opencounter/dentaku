require 'dentaku/ast/function'

Dentaku::AST::Function.register('first([%a]) = %a', ->(list) {
  raise Dentaku::EmptyList.new(self) if list.empty?

  list.first
})

Dentaku::AST::Function.register('last([%a]) = %a', ->(list) {
  raise Dentaku::EmptyList.new(self) if list.empty?

  list.last
})

Dentaku::AST::Function.register('map([%a], \%a => %b) = %b', ->(list, lam) {
  list.map(&lam)
})
