@RestResource(urlMapping='/RenewalOpportunityImport/*')
global without sharing class RenewalOpportunityImporter {
    private static final Logger LOGGER = LogFactory.create(RenewalOpportunityImporter.class);
    
	@HttpPost
    global static RenewalResponseData processRenewal(RenewalData renewal) {
        LOGGER.info('Processing renewal for email {0}', renewal.email);
        List<Contact> renewalContacts = [SELECT Id FROM Contact WHERE Email = :renewal.email];
        
        Contact renewalContact = null;
        if (renewalContacts.size() > 0) {
            renewalContact = renewalContacts.get(0);
        }
        
        List<Account> renewalAccounts = [SELECT Id, Name, OwnerId FROM Account WHERE Gearset_team__r.Gearset_team_id__c = :renewal.teamId];
        
        Account renewalAccount = null;
        if (renewalAccounts.size() > 0) {
            renewalAccount = renewalAccounts.get(0);
        } else {
            throw new IllegalArgumentException('Could not find account for renewal: ' + renewal.teamId);
        }
        
        // TODO: Log active opportunities for contact
         
        String opportunityName = getOpportunityName(renewalAccount, renewal);
        
        Id owner = CsmAssignment.assigneeForNewRenewalOpp(renewalAccount);
        LOGGER.info('Assigning new renewal opportunity to {0}', owner);
        
        String recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Gearset Renewals Process').getRecordTypeId();
        
        // TODO: Add correct opportunity line items to opportunity
        Date closeDate = Date.newInstance(renewal.licenseExpiry.year(), renewal.licenseExpiry.month(), renewal.licenseExpiry.day());
        
        Id renewalContactId = renewalContact != null ? renewalContact.Id : null;
        
        Opportunity newOpportunity = new Opportunity(
            Name = opportunityName,
            AccountId = renewalAccount.Id,
            ContactId = renewalContactId,
            CloseDate = closeDate,
            OwnerId = owner,
            RecordTypeId = recordTypeId,
            StageName = 'Approaching Renewal',
            Renewal_Date__c = closeDate,
            Type = 'Renewal'
        );
        
        insert newOpportunity;
        
        addNoteToOpportunity(newOpportunity, renewal);
        
        addTaskForRenewal(newOpportunity, renewalContactId);
        
        RenewalResponseData responseData = new RenewalResponseData();
        responseData.newOpportunityId = newOpportunity.Id;
        return responseData;
    }
    
    private static String getOpportunityName(Account renewalAccount, RenewalData renewal) {
        String expiry = 'Expiry: ' + renewal.licenseExpiry.format('d MMM yyyy');
        String person = renewal.firstName + ' ' + renewal.surname;
        
        return renewalAccount.Name + ' Renewal (' + expiry + ') (' + person + ')';
    }
    
    private static void addTaskForRenewal(Opportunity newOpportunity, Id renewalContactId) {
        Task t = new Task(
            Subject = 'Contact about upcoming renewal',
            Status = 'Open',
            Priority = 'Normal',
            WhoId = renewalContactId,
            WhatId = newOpportunity.Id,
            OwnerId = newOpportunity.OwnerId,
            ActivityDate = Date.today()
        );
        
        insert t;
    }
    
    private static void addNoteToOpportunity(Opportunity newOpportunity, RenewalData data) {
        ContentNote note = new ContentNote();
        
        note.Title = 'Renewal data';
        
        String content = '';
        content += 'LicenseId: ' + data.licenseId;
        content += ', LicensePlanId: ' + data.licensePlanId;
        content += ', LicenseQuantity: ' + data.licenseQuantity;
        content += ', FastspringReference: ' + data.fastspringReference;
        note.Content = Blob.valueOf(content);
        
        insert note;
        
		ContentDocumentLink link = new ContentDocumentLink();
		link.LinkedEntityId = newOpportunity.Id;
		link.ContentDocumentId = note.Id;
		link.shareType = 'V';
        
		insert link;
    }
    
    global class RenewalData {
        global String email { get; set; }
        global String teamId { get; set; }
        global DateTime licenseExpiry { get; set; }
        global String firstName { get; set; }
        global String surname { get; set; }
        global String licenseId { get; set; }
        global Integer licensePlanId { get; set; }
        global Integer licenseQuantity { get; set; }
        global String fastspringReference { get; set; }
    }
    
    global class RenewalResponseData {
        global String newOpportunityId { get; set; }
    }
}