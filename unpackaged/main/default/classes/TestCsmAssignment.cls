@isTest
private class TestCsmAssignment {  
    private static UserRole csmRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Customer_Success_Manager'];
    
    private static User getCsmUser() {
        User u = TestUtils.createStandardUser('CSM', 'csm@gearset.com');

        u.UserRoleId = csmRoleId.Id;
        return u;
    }
    
	@isTest
    public static void shouldNotSetOwnerOrChurnRiskIfAlreadySetAndMrrLessThan1000() {
        User u = TestUtils.createStandardUser('Last', 'my@email.com');

        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
        );
        upsert t;

        insert u;
        Account a = new Account(
            Name = 'My account',
            OwnerId = u.Id,
            Churn_risk__c = 'Churn Risk - Attempting Contact',
            Gearset_Team__c = t.Id
        );
        insert a;
        
        Opportunity o = new Opportunity(
        	Name = 'My account op',
            StageName = 'Closed Won',
            OwnerId = u.Id,
            AccountId = a.Id,
            Amount = 300,
            CloseDate = Date.today(),
            LeadSource = 'Inbound',
            Type = 'New'
        );
        insert o;
        
        CsmAssignment.handleWonOpportunity(o);
        
        Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(a.OwnerId, updatedAccount.OwnerId);
        System.assertEquals('Churn Risk - Attempting Contact', updatedAccount.churn_risk__c);
    }
    
    @isTest
    public static void shouldSetOwnerToACsmIfMrrGreaterThan1000AndNotCurrentAssignedToOne() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception
            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            User u = TestUtils.createStandardUser('Last', 'my@email.com');
            insert getCsmUser();
            insert u;
            Account a = new Account(
                Name = 'My account',
                OwnerId = u.Id,
                Churn_risk__c = 'Ramped',
                Gearset_Team__c = t.Id
            );
            insert a;
            
            Opportunity o = new Opportunity(
                Name = 'My account op',
                StageName = 'Closed Won',
                OwnerId = u.Id,
                AccountId = a.Id,
                Amount = 3000,
                CloseDate = Date.today(),
         	    LeadSource = 'Inbound',
                Type = 'New'
            );
            insert o;
            
            CsmAssignment.handleWonOpportunity(o);
            
            Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
            System.assertNotEquals(u.Id, updatedAccount.OwnerId);
            System.assertEquals('Onboarding', updatedAccount.Churn_risk__c);
        }
    }
    
    @isTest
    public static void shouldNotModifyAccountOver1000MrrIfOwnerIsAlreadyACsm() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception
            User csmUser = getCsmUser();
            insert csmUser;
            User u = TestUtils.createStandardUser('Last', 'my@email.com');
            insert u;

            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;
    
            Account a = new Account(
                Name = 'My account',
                OwnerId = csmUser.Id,
                Churn_risk__c = 'Ramped',
                Gearset_Team__c = t.Id
            );
            insert a;
            
            Opportunity o = new Opportunity(
                Name = 'My account op',
                StageName = 'Closed Won',
                OwnerId = u.Id,
                AccountId = a.Id,
                Amount = 3000,
                CloseDate = Date.today(),
      	        LeadSource = 'Inbound',
                Type = 'New'
            );
            insert o;
            
            CsmAssignment.handleWonOpportunity(o);
            
            Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
            System.assertEquals(csmUser.Id, updatedAccount.OwnerId);
            System.assertEquals('Ramped', updatedAccount.Churn_risk__c);
        }
    }
    
    @isTest
    public static void shouldChurnRiskForAccountsWithoutForSmallDeals() {
        User u = TestUtils.createStandardUser('Last', 'my@email.com');
        insert u;

        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
        );
        upsert t;

        Account a = new Account(
            Name = 'My account',
            Gearset_Team__c = t.Id,
            Churn_Risk__c = null
        );
        insert a;
        
        Opportunity o = new Opportunity(
        	Name = 'My account op',
            StageName = 'Closed Won',
            OwnerId = u.Id,
            AccountId = a.Id,
            Amount = 300,
            CloseDate = Date.today(),
            LeadSource = 'Inbound',
            Type = 'New'
        );
        insert o;
        
        CsmAssignment.handleWonOpportunity(o);
        
        Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
        System.assertEquals('Ramped', updatedAccount.churn_risk__c);
    }
    
    @isTest
    public static void shouldReturnAccountOwnerIfCurrentOwnerIsACsm() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception
            User csmUser = getCsmUser();
            insert csmUser;
            
            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;
            
            Account a = new Account(
                Name = 'Some Account',
                OwnerId = csmUser.Id,
                Gearset_Team__c = t.Id
            );
            
            insert a;
            
            Id assigneeId = CsmAssignment.assigneeForNewRenewalOpp(a);
            
            System.assertEquals(csmUser.Id, assigneeId);
        }
    }
    
    @isTest
    public static void shouldPickACsmIfAccountOwnerIsNotOne() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception
            User csmUser = getCsmUser();
            insert csmUser;
            User u = TestUtils.createStandardUser('Last', 'my@email.com');
            insert u;

            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;
    
            Account a = new Account(
                Name = 'My account',
                OwnerId = u.Id,
                Churn_risk__c = 'Ramped',
                Gearset_Team__c = t.Id
            );
            insert a;
                        
            Id assigneeId = CsmAssignment.assigneeForNewRenewalOpp(a);
            System.assertNotEquals(u.Id, assigneeId);
        }
    }
}