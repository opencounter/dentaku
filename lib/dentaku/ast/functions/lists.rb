require 'dentaku/ast/function'

Dentaku::AST::Function.register('first([%a]) = %a', ->(list) {
  raise Dentaku::EmptyList.new(self) if list.empty?

  list.first
})

Dentaku::AST::Function.register('last([%a]) = %a', ->(list) {
  raise Dentaku::EmptyList.new(self) if list.empty?

  list.last
})

Dentaku::AST::Function.register('each([%a], ?%a => %b) = [%b]', ->(list, lam) {
  list.map(&lam)
})

Dentaku::AST::Function.register('roll(%b, [%a], ?%b ?%a => %b) = %b', ->(init, list, lam) {
  list.inject(init, &lam)
})

Dentaku::AST::Function.register('filter([%a], ?%a => :bool) = [%a]', ->(list, lam) {
  list.filter(&lam)
})
