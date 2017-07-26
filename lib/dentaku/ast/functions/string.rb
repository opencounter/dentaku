Dentaku::AST::Function.register(
  'match(:string, :string) = :bool', ->(string, pattern) {
    !string.match(Regexp.new(pattern)).nil?
  }
)
