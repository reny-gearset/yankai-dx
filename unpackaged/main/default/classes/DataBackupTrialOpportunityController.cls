@RestResource(urlMapping='/DataBackupTrialOpportunity')
global without sharing class DataBackupTrialOpportunityController {
    private static final Logger LOGGER = LogFactory.create(DataBackupTrialOpportunityController.class);

    @HttpPost
    global static DataBackupTrialOpportunityResponse createDataBackupTrialOpportunity() {
        LOGGER.info('Creating Data Backup trial opportunity');

        RestRequest restRequest = RestContext.request;
        String requestBody = restRequest.requestbody.tostring();

        LOGGER.info('Deserializing request body {0}', requestbody);

        DataBackupTrialOpportunityRequest request = (DataBackupTrialOpportunityRequest) JSON.deserialize(
            requestBody,
            DataBackupTrialOpportunityRequest.class
        );

        Id expansionOpportunityId = ExpansionService.createDataBackupTrialOpportunity(request.teamId, request.email);

        DataBackupTrialOpportunityResponse response = new DataBackupTrialOpportunityResponse();
        response.opportunityId = expansionOpportunityId;
        return response;
    }

    global class DataBackupTrialOpportunityRequest {
        global string email { get; set; }
        global string teamId { get; set; }
    }

    global class DataBackupTrialOpportunityResponse {
        global Id opportunityId { get; set; }
    }
}