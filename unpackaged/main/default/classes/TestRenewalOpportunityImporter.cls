@isTest
private class TestRenewalOpportunityImporter {
    private static final Logger LOGGER = LogFactory.create(TestRenewalOpportunityImporter.class);
    
    private static UserRole csmRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Customer_Success_Manager'];

	@isTest
    public static void shouldCreateRenewalOpportunityCorrectly() {
        Contact c = new Contact();
        c.Email = 'ben.roberts@gearset.com';
        c.FirstName = 'Ben';
        c.LastName = 'Roberts';
        insert c;

        Gearset_Team__c gt = new Gearset_Team__c(
            Gearset_Team_Id__c = 'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076'
        );
        upsert gt;

        LOGGER.info('Inserted test Gearset_team__c {0}', gt.Id);
        
        Account a = new Account();
        a.Name = 'Gearset';
        a.Gearset_team__c = gt.Id;
        insert a;
                
        RenewalOpportunityImporter.RenewalData data = new RenewalOpportunityImporter.RenewalData();
        
        data.email = 'ben.roberts@gearset.com';
        data.teamId = 'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076';
        data.firstName = 'Ben';
        data.surname = 'Roberts';
        data.licenseExpiry = DateTime.newInstance(2020, 8, 20);
        data.licenseId = 'abcd';
        data.licensePlanId = 35;
        data.licenseQuantity = 28;
        data.fastspringReference = 'GEA-123-123-123';
        
        RenewalOpportunityImporter.processRenewal(data);
        
        // Check the opportunity was created correctly
        
        Opportunity opp = [SELECT Name, AccountId, ContactId, CloseDate, Owner.UserRoleId, RecordTypeId, StageName, Renewal_Date__c FROM Opportunity];
        
        System.assertEquals('Gearset Renewal (Expiry: 20 Aug 2020) (Ben Roberts)', opp.Name);
        System.assertEquals(a.Id, opp.AccountId);
        System.assertEquals(c.Id, opp.ContactId);
        System.assertEquals(data.licenseExpiry.year(), opp.CloseDate.year());
        System.assertEquals(data.licenseExpiry.month(), opp.CloseDate.month());
        System.assertEquals(data.licenseExpiry.day(), opp.CloseDate.day());
        System.assertEquals(opp.CloseDate, opp.Renewal_Date__c);
        System.assertEquals(csmRoleId.Id, opp.Owner.UserRoleId);
        // 'Gearset Renewals Process'
        System.assertEquals('0124K000000pyVaQAI', opp.RecordTypeId); // NOPMD - hard coded id
        System.assertEquals('Approaching Renewal', opp.StageName);
        
        // Check an associated task has been created correctly
        
        Task t = [SELECT Subject, Status, Priority, WhatId, WhoId, OwnerId FROM Task];
        
        System.assertEquals('Contact about upcoming renewal', t.Subject);
        System.assertEquals('Open', t.Status);
        System.assertEquals('Normal', t.Priority);
        System.assertEquals(opp.Id, t.WhatId);
        System.assertEquals(c.Id, t.WhoId);
        System.assertEquals(opp.OwnerId, t.OwnerId);
        
        // Check an associated content note has been created correctly
        
        List<ContentDocumentLink> links = [SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id];
        
        System.assertEquals(links.size(), 1);
        System.assertEquals(links.get(0).ContentDocument.Title, 'Renewal data');
    }
    
    @isTest
    public static void shouldThrowIfAccountNotFound() {
        RenewalOpportunityImporter.RenewalData data = new RenewalOpportunityImporter.RenewalData();
        
        data.email = 'ben.roberts@gearset.com';
        data.teamId = 'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076';
        data.firstName = 'Ben';
        data.surname = 'Roberts';
        data.licenseExpiry = DateTime.newInstance(2020, 8, 20);
        
        Boolean pass = false;
        try {
        	RenewalOpportunityImporter.processRenewal(data);
        } 
        catch (IllegalArgumentException e) {
            pass = true;
        }
        
        System.assert(pass);
    }
}