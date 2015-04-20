class Service::ZohoProjects < Service::Base
    title "Zoho Projects"

    string :project_id , :placeholder => "" ,
        :label => "Project ID and Auth Token is required " \
	" for configuration which will be available " \
	" under 'Dashboard' --> 'Project Customization' " \
	"--> 'Service Hooks' " \
	"<br /><br />" \
            "Project ID"
    
    string :auth_token ,:label => "Auth Token", :placeholder => ""

    def receive_issue_impact_change(config, issue)
        payload = JSON.generate issue

        response = send_request_to_projects config, payload
        if response.status != 200
            raise "Problem while sending request to Zoho Projects, Status : #{response.status}, Body: #{response.body}"
        end

        return { zohoprojects_bug_id: response.body }
    end

    def receive_verification(config, issue)
        payload = JSON.generate({event: "verification"})

        response = send_request_to_projects config, payload
        if response.status == 400
            return [false, "Invalid Auth Token/Project ID"]
        end

        [ true, "Verification successfully completed" ]
    end

    private
    def base_url
        return "https://projectsapi.zoho.com"
    end

    def service_hook_url
        return base_url + "/serviceHook"
    end

    def send_request_to_projects config, payload
        http.ssl[:verify] = true

        response = http_post service_hook_url do |req|
            req.params[:authtoken] = config[:auth_token]
            req.params[:pId] = config[:project_id]
            req.params[:pltype] = "chook"
            req.params[:payload] = payload
        end

        return response
    end
end
