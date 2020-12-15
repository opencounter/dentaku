require 'dentaku/ast/function'

Dentaku::AST::Function.register('concat([%a], [%a]) = [%a]', ->(*args) {
  args.inject(&:concat)
})
