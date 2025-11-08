require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  it 'is a subclass of ActiveJob::Base' do
    expect(ApplicationJob < ActiveJob::Base).to be true
  end
end
