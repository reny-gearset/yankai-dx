@RestResource(urlMapping='/LeadUpdate/*')
global without sharing class LeadAdditionalInformationController {
	@HttpPatch
    global static void addAdditionalLeadInformation(LeadInformation additionalInformation) {
        RestRequest request = RestContext.request;
        String leadId = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
        
        Lead l = [SELECT Id FROM Lead WHERE Id = :leadId];
        
        if (additionalInformation.leadQuality != 'Unknown') {
            l.Rating = additionalInformation.leadQuality;
        }

        if (additionalInformation.timezone != null) {
        	l.Timezone__c = additionalInformation.timezone;
        }
        
        update l;
    } 
    
    global class LeadInformation {
        global string leadQuality;
        global string timezone;
    }
}