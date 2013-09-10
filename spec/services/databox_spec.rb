# encoding: utf-8

require 'spec_helper'
require 'uri'
require 'webmock/rspec'

describe Service::Databox do
  # Takes a URL and returns new URL string with necessary basic auth
  def databox_url_with_auth(url, push_token)
    uri = URI(url)
    uri.user = push_token
    uri.password = ''
    uri.to_s
  end

  let(:config_fixture) do
    {
      :push_url => 'https://app.databox.com/push/custom/mock_push_url_id',
      :push_token => 'mock_push_token'
    }
  end

  it 'should have a title' do
    Service::Databox.title.should == 'Databox'
  end

  it 'should require one page of information' do
    Service::Databox.pages.should == [
      { title: 'Push Connection Settings', attrs: [:push_url, :push_token] }
    ]
  end

  describe :receive_verification do
    let(:service) { Service::Databox.new('logs', {}) }
    let(:payload) { {} }

    it 'should respond' do
      service.respond_to?(:receive_verification)
    end

    it 'should succeed upon successful API response' do
      verification_url = databox_url_with_auth("#{config_fixture[:push_url]}/logs", config_fixture[:push_token])
      stub_request(:get, verification_url).to_return({
        :status => 200,
        :body => ''
      })

      resp = service.receive_verification(config_fixture, payload)
      resp.should == [true, 'Successfully verified Databox connection!']
    end

    it 'should fail upon unsuccessful API response' do
      verification_url = databox_url_with_auth("#{config_fixture[:push_url]}/logs", config_fixture[:push_token])
      stub_request(:get, verification_url).to_return({
        :status => 500,
        :body => ''
      })

      resp = service.receive_verification(config_fixture, payload)
      resp.should == [false, 'Oops! Please check your settings again.']
    end
  end

  describe :receive_issue_impact_change do
    let(:service) { Service::Databox.new('push', {}) }
    let(:payload) do
      {
        title:                  'issue title',
        method:                 'method name',
        impact_level:           1,
        impacted_devices_count: 1,
        crashes_count:          1,
        app: {
          name:              'app name',
          bundle_identifier: 'foo.bar.baz',
          platform:          'ios'
        },
        url: 'http://foo.com/bar'
      }
    end
    let(:push_url) do
      databox_url_with_auth(config_fixture[:push_url], config_fixture[:push_token])
    end

    it 'should respond to receive_issue_impact_change' do
      service.respond_to?(:receive_issue_impact_change)
    end

    it 'should succeed upon successful API response' do
      stub_request(:post, push_url).to_return({
        :status => 200,
        :body => {
          response: {
            type: 'success',
            message: 'Items stored: 1'
          }
        }.to_json
      })

      resp = service.receive_issue_impact_change(config_fixture, payload)
      resp.should == :no_resource
    end

    it 'should fail upon unsuccessful API response' do
      stub_request(:post, push_url).to_return({
        :status => 500,
        :body => {
          response: {
            type: 'failed',
            message: 'reason'
          }
        }.to_json
      })

      lambda { service.receive_issue_impact_change(config_fixture, payload) }.should raise_error(StandardError, 'Pushing data to Databox failed: , {"response":{"type":"failed","message":"reason"}}')
    end
  end
end