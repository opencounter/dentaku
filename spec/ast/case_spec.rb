require 'spec_helper'

describe Dentaku::AST::Case do
  describe '#dependencies' do
    let(:node) { Dentaku::Syntax.parse(<<-DENTAKU) }
      CASE fruit
      WHEN "apple" THEN 1
      WHEN "banana" THEN tax + 2
      ELSE fallback
      END
    DENTAKU

    it 'gathers dependencies from switch and conditionals' do
      expect(node.dependencies).to eq(['fruit', 'tax', 'fallback'])
    end
  end
end
