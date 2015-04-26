require 'spec_helper'

describe Service::ZohoProjects do
  let(:config) do
    {
# TODO - project id & token has to copied from Dashboard -> Project Customization 
      :project => 'sample_project_id',
      :private_token => 'sample_private_token',
      :url => 'https://projectsapi.zoho.com/serviceHook'
    }
  end

  it 'should have a title' do
    Service::ZohoProjects.title.should == 'ZohoProjects'
  end

  describe :receive_verification do
    it :success do
      service = Service::ZohoProjects.new('verification', {})
      success, message = service.receive_verification(config, nil)
      success.should be true
    end
  end

  describe :receive_issue_impact_change do
    let(:payload) do
        {
            :title => 'foo title',
            :impact_level => 1,
            :impacted_devices_count => 1,
            :crashes_count => 1,
            :app => {
                :name => 'foo name',
                :bundle_identifier => 'foo.bar.baz'
            }
        }
    end

    it 'should create a new issue' do
      service = Service::ZohoProjects.new('issue_impact_change', {})
      response = service.receive_issue_impact_change(config, payload)
      response.not_to eql("")
    end
  end
end
