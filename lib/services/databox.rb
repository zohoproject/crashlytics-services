# encoding: utf-8

# The Service::Databox is a class responsible for handling Databox.com
# Connection settings and acting in response to events it receives from
# Crashlytics
class Service::Databox < Service::Base
  title 'Databox'

  string :push_url, :placeholder => 'https://app.databox.com/push/custom/xyz', :label =>
    'Databox configuration for Crashlytics is available <A target="_blank" href="https://app.databox.com/apps/Crashlytics/connect">here</A>.' \
    '<br /><br />' \
    'Databox push URL'
  string :push_token, :placeholder => 'Token', :label => 'Databox token for Crashlytics'

  page 'Push Connection Settings', [:push_url, :push_token]

  def receive_verification(config, _)
    resp = verify_access(config[:push_token], config[:push_url])
    if resp.status == 200
      [true,  'Successfully verified Databox connection!']
    else
      log "Databox HTTP error, status code: #{resp.status}, body: #{resp.body}"
      [false, 'Oops! Please check your settings again.']
    end
  rescue => exception
    log "Rescued a verification error in Databox: (config[push_url]=#{config[:push_url]}) #{exception}"
    [false, 'Oops! Please check your settings again.']
  end

  # Push data to Databox, raise on error
  def receive_issue_impact_change(config, payload)
    resp = post_new_issue(config[:push_url], config[:push_token], payload[:impacted_devices_count], payload[:crashes_count])
    raise "Pushing data to Databox failed: #{resp[:status]}, #{resp.body}" unless resp.status == 200
    :no_resource
  end

  private
  def verify_access(push_token, push_url)
    http.ssl[:verify] = true
    http.basic_auth push_token, ''
    http_get "#{push_url}/logs"
  end

  # POSTs new issue to Databox Crashlytics integration point, raising on error.
  def post_new_issue(push_url, push_token, impacted_devices_count, crashes_count)
    post_body = {
      data: [
        { :key => 'impacted_devices_count', :value => impacted_devices_count },
        { :key => 'crashes_count', :value => crashes_count }
      ]
    }

    http.ssl[:verify] = true
    http.basic_auth push_token, ''
    http_post push_url do |req|
      req.body = post_body.to_json
    end
  end
end