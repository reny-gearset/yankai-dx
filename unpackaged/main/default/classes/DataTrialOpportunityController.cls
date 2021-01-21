@RestResource(urlMapping='/DataDeploymentTrialOpportunity')
global without sharing class DataTrialOpportunityController {
	@HttpPost
    global static DataDeploymentTrialOpportunityResponse createDataDeploymentTrialOpportunity() {
        RestRequest restRequest = RestContext.request;
        DataDeploymentTrialOpportunityRequest request = (DataDeploymentTrialOpportunityRequest) JSON.deserialize(restRequest.requestbody.tostring(), DataDeploymentTrialOpportunityRequest.class);
        
		Id expansionOpportunityId = ExpansionService.createDataDeploymentTrialOpportunity(request.teamId, request.email);
        
        DataDeploymentTrialOpportunityResponse response = new DataDeploymentTrialOpportunityResponse();
        response.opportunityId = expansionOpportunityId;
		return response;        
    }
    
    global class DataDeploymentTrialOpportunityRequest {
        global string email { get; set; }
        global string teamId { get; set; }
    }
        
    global class DataDeploymentTrialOpportunityResponse {
        global Id opportunityId { get; set; }
    }
}