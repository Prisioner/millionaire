require 'rails_helper'

RSpec.describe 'users/index', type: :view do
  before(:each) do
    assign(:users, [
      FactoryGirl.build_stubbed(:user, name: 'Василий', balance: 100500),
      FactoryGirl.build_stubbed(:user, name: 'Аркадий', balance: 25000)
    ])

    render
  end

  it 'renders player names' do
    expect(rendered).to match 'Василий'
    expect(rendered).to match 'Аркадий'
  end

  it 'renders player balances' do
    expect(rendered).to match '100 500 ₽'
    expect(rendered).to match '25 000 ₽'
  end

  it 'renders player names in right order' do
    expect(rendered).to match /Василий.*Аркадий/m
  end
end