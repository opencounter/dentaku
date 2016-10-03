require 'spec_helper'

describe Dentaku::Type::Constraint do
  let(:lhs) { Dentaku::Type::Expression.syntax({}) }
  let(:rhs) { Dentaku::Type::Expression.make_variable('foo') }
  let(:reason) { Dentaku::Type::Reason.literal({}) }
  subject(:constraint) { Dentaku::Type::Constraint.new(lhs, rhs, reason) }

  it 'maps sides' do
    mapped = constraint.map_lhs do
      Dentaku::Type::Expression.make_variable('bar')
    end

    expect(mapped.lhs).not_to be(constraint.lhs)
    expect(mapped.lhs.name).to eql('bar')
    expect(mapped.rhs).to be(constraint.rhs)
    expect(mapped.reason).to be(constraint.reason)
  end

  it 'swaps sides' do
    swapped = constraint.swap
    expect(swapped.lhs).to be(constraint.rhs)
    expect(swapped.rhs).to be(constraint.lhs)
    expect(swapped.reason).to be(constraint.reason)
  end

  it 'conjoins' do
    conjoined = constraint & constraint
    expect(conjoined.lhs).to be(constraint.rhs)
    expect(conjoined.rhs).to be(constraint.rhs)
    expect(conjoined.reason).not_to be(constraint.reason)
    expect(conjoined.reason.conjunction?).to be(true)
  end
end
