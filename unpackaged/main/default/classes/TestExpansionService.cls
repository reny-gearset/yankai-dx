@isTest
public class TestExpansionService {
    private static final Logger LOGGER = LogFactory.create(TestExpansionService.class);

	@isTest
    public static void testCreateExpansionsRoundRobinsSdrs() {
        String testEmail = 'test@example.com';
        String testTeamId = '2027f58d-35ef-4101-b237-9b6378fa74c2';
        setupAccount(testTeamId, testEmail);
        
        Id backupOppId = ExpansionService.createDataBackupTrialOpportunity(testTeamId, testEmail);
        Opportunity backupOpportunity = [ SELECT OwnerId FROM Opportunity WHERE Id = :backupOppId ];
        
        Id dataOppId = ExpansionService.createDataDeploymentTrialOpportunity(testTeamId, testEmail);
        Opportunity dataOpportunity = [ SELECT OwnerId FROM Opportunity WHERE Id = :dataOppId ];
        
		Id backupOppOwner = backupOpportunity.Id;
        Id dataOppOwner = dataOpportunity.Id;
        
        System.assertNotEquals(backupOppOwner, null);
        System.assertNotEquals(backupOppOwner, dataOppOwner);
    }   

    @isTest
    public static void createDataDeploymentTrialOpportunitySetsAccountNameForContactIfContactNotFound() {        
        String testEmail = 'test@example.com';
        String testTeamId = '2027f58d-35ef-4101-b237-9b6378fa74c2';
        
        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = testTeamId
        );
        insert t;

        LOGGER.info('Inserted test Gearset_team__c ' + t.Id);

        Account accountTest = new Account(
            Name = 'TestAccount',
        	Gearset_team__c = t.Id
        );
        
        insert accountTest;
        
        Id dataOppId = ExpansionService.createDataDeploymentTrialOpportunity(testTeamId, testEmail);
        Opportunity dataOpportunity = [ SELECT OwnerId, Name FROM Opportunity WHERE Id = :dataOppId ];
        
        System.assertEquals('Data deployment trial for TestAccount', dataOpportunity.Name);
    }
    
    @isTest
    public static void createDataBackupTrialOpportunityCreatesTask() {        
        String testEmail = 'test@example.com';
        String testTeamId = '2027f58d-35ef-4101-b237-9b6378fa74c2';
        
        setupAccount(testTeamId, testEmail);
        
        Id dataOppId = ExpansionService.createDataBackupTrialOpportunity(testTeamId, testEmail);
        
        Task dataBackupTask = [ SELECT Subject FROM Task WHERE WhatId = :dataOppId ];
        
        System.assertEquals('Work with Firstname Contact to get going with backup', dataBackupTask.Subject);
    }
    
    @isTest
    public static void ccreateDataDeploymentTrialOpportunityCreatesTask() {        
        String testEmail = 'test@example.com';
        String testTeamId = '2027f58d-35ef-4101-b237-9b6378fa74c2';
        
        setupAccount(testTeamId, testEmail);
        
        Id dataOppId = ExpansionService.createDataDeploymentTrialOpportunity(testTeamId, testEmail);
        
        Task dataBackupTask = [ SELECT Subject FROM Task WHERE WhatId = :dataOppId ];
        
        System.assertEquals('Work with Firstname Contact to get going with data deployment', dataBackupTask.Subject);
    }
    
    static void setupAccount(String teamId, String email) {
        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = teamId
        );
        upsert t;

        LOGGER.info('Inserted test Gearset_team__c {0}', t.Id);

        Account accountTest = new Account(
            Name = 'TestAccount',
        	Gearset_team__c = t.Id
        );
        
        insert accountTest;
        
        Contact contactTest = new Contact(
            FirstName = 'Firstname',
            LastName = 'Contact',
            Email = email,
            AccountId = accountTest.Id
        );
        
        insert contactTest;        
    }
}