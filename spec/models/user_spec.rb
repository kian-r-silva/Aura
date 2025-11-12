require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations and associations' do
    subject { build(:user) }

    it { is_expected.to have_many(:reviews).dependent(:destroy) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to validate_uniqueness_of(:username) }
    it { is_expected.to have_secure_password }
  end
end
