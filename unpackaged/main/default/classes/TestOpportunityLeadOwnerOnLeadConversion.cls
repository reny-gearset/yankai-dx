@isTest
private class TestOpportunityLeadOwnerOnLeadConversion {
    @isTest static void shouldFillOpportunityLeadOwnerOnLeadConversion() {
        Database.LeadConvertResult lcr = createAndConvertLead();
        
        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Id, LeadOwner__c from Opportunity WHERE Id = :opportunityId];
        
        System.assertEquals(opp.LeadOwner__c, UserInfo.getUserId());
    }
    
    @isTest static void shouldLeaveFilledOpportunityLeadOwnerOnLeadConversion() {
        User user = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() LIMIT 1];
        Id ownerId = user.Id;
        
        Database.LeadConvertResult lcr = createAndConvertLead(ownerId);

        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Id, LeadOwner__c from Opportunity WHERE Id = :opportunityId];
        
        System.assertEquals(opp.LeadOwner__c, ownerId);
        
        Database.LeadConvertResult lcr2 = createAndConvertLead(UserInfo.getUserId(), lcr);
        
        Id reusedOpportunityId = lcr2.getOpportunityId();
        Opportunity reusedOpp = [SELECT Id, LeadOwner__c from Opportunity WHERE Id = :reusedOpportunityId];
        
        System.assertEquals(reusedOpportunityId, opportunityId);
        System.assertEquals(reusedOpp.LeadOwner__c, opp.LeadOwner__c);
    }
    
    private static Database.LeadConvertResult createAndConvertLead() {
        return createAndConvertLead(null, null);
    }
    
    private static Database.LeadConvertResult createAndConvertLead(Id ownerId) {
        return createAndConvertLead(ownerId, null);
    }
    
    private static Database.LeadConvertResult createAndConvertLead(Id ownerId, Database.LeadConvertResult existingLcr) {
        Lead myLead = new Lead(
        	LastName = 'Yankai',
            Company = 'Gearset',
            LeadSource = 'Inbound'
        );
        
        if (ownerId == null) {
            myLead = new Lead(
                LastName = 'Yankai',
                Company = 'Gearset',
                LeadSource = 'Inbound'
            );
        } else {
            myLead = new Lead(
                LastName = 'Yankai',
                Company = 'Gearset',
                LeadSource = 'Inbound',
                OwnerId = ownerId
            );
        }
        
        insert myLead;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(myLead.Id);
        lc.setConvertedStatus('Demo Booked');
        
        if (existingLcr != null) {
            lc.setOpportunityId(existingLcr.getOpportunityId());
            lc.setAccountId(existingLcr.getAccountId());
        }
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        return lcr;
    }
}