require 'spec_helper'

describe 'Declared Types' do
  Dentaku::Type.declare(:fake_struct) do
    structable(a: ':numeric', b: ':numeric')
  end

  Dentaku::Type.declare(:recursive) do
    structable(a: ':recursive', b: ':numeric')
  end

  it 'destructs a structable type' do
    checker = Dentaku::Type::StaticChecker.new(x: :fake_struct)
    ast = Dentaku::Syntax.parse('x.a.a.a.a.b')

    checker.check!(ast)
  end

  it 'recursively destructs a structable type' do
    checker = Dentaku::Type::StaticChecker.new(x: :fake_struct)
    ast = Dentaku::Syntax.parse('x.a.a.a.a.b')

    checker.check!(ast)
  end
end
