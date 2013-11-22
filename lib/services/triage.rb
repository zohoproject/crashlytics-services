class Service::Triage < Service::Base
  title "Triage"
  string :api_key, :placeholder => "GX5CG427",
         :label => 'Your Triage API Key. ' \
                   '(located on the Crashlytics settings page in your Triage app.)'
  page "API Key", [ :api_key ]

  # Create an issue
  def receive_issue_impact_change(config, payload)
    ok = post_event(webhook_url(config[:api_key]), 'issue_impact_change', 'issue', payload)
    raise "Triage Issue Create Failed: #{ payload }" unless ok
    # return :no_resource if we don't have a resource identifier to save
    :no_resource
  end

  def receive_verification(config, _)
    success = [true,  "Successfully verified Triage integration!"]
    failure = [false, "Oops! Please check your API token again."]
    ok = post_event(webhook_url(config[:api_key]), 'verification', 'none', nil)
    ok ? success : failure
  rescue => e
    log "Rescued a verification error in Triage: (url=#{webhook_url}) #{e}"
    failure
  end

  private

  # Triage webhook url
  def webhook_url api_key
  	puts "https://www.triaged.co/crashlytics/#{api_key}"
  	"https://www.triaged.co/crashlytics/#{api_key}"
  end

  # Post an event string to a url with a payload hash
  # Returns true if the response code is anything 2xx, else false
  def post_event(url, event, payload_type, payload)
    body = {
      :event        => event,
      :payload_type => payload_type }
    body[:payload]  =  payload if payload

    resp = http_post url do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body                    = body.to_json
      req.params['verification']  = 1 if event == 'verification'
    end
    ok = (200..299).include? resp.status
    log "HTTP Error: status code: #{ resp.status }, body: #{ resp.body }" unless ok
    ok
  end
end
