require 'test_helper'

class PasswordResetTest < ActiveSupport::TestCase
  let(:account) { create(:account) }

  describe 'new' do
    it 'must assign passed attributes as instance variables' do
      email = Faker::Internet.email
      password_reset = PasswordReset.new(email: email)
      password_reset.instance_variable_get('@email').must_equal email
    end
  end

  describe 'persisted?' do
    it 'wont be a persisted record' do
      password_reset = PasswordReset.new(email: account.email)
      password_reset.wont_be :persisted?
    end
  end

  describe 'refresh_token_and_email_link' do
    before do
      password_reset = PasswordReset.new(email: account.email)
      password_reset.refresh_token_and_email_link
      account.reload
    end

    it 'must set a value for reset_password_tokens' do
      account.reset_password_tokens.must_be :present?
    end

    it 'must set a token in account' do
      account.reset_password_tokens.keys.first.must_be :present?
    end

    it 'must set a timestamp for expiration' do
      timestamp = account.reset_password_tokens.values.first
      timestamp.must_be :<=, Time.now.utc.advance(hours: 4)
      timestamp.must_be :>, Time.now.utc.advance(hours: 3, minutes: 58)
    end
  end
end
