Dentaku::AST::Function.register(
  'match(:string, :string) = :bool', ->(string, pattern) {
    !string.match(Regexp.new(pattern)).nil?
  }
)

# blank?
Dentaku::AST::Function.register(
  'blank(:string) = :bool', ->(string) {
    string.empty?
  }
)
