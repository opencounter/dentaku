require_relative '../function'

Dentaku::AST::Function.register(:concat, :list, ->(*args) {
  args.inject(&:concat)
})
