public without sharing class ExpansionService {
    private static final Logger LOGGER = LogFactory.create(ExpansionService.class);

    public static Id createDataBackupTrialOpportunity(String teamId, String email) {
		Account account = getAccount(teamId, email);
        Contact expansionContact = getContact(account.Contacts);
        String contactName = getContactName(expansionContact, account);        
        
		Opportunity backupOpportunity = createExpansionOpportunity('Data backup trial for ' + contactName, expansionContact, account);
        
        createTask(backupOpportunity, String.format('Work with {0} to get going with backup', new List<Object> { contactName }));
                
        return backupOpportunity.Id;
    }
    
    public static Id createDataDeploymentTrialOpportunity(String teamId, string email) {
        Account account = getAccount(teamId, email);
        Contact expansionContact = getContact(account.Contacts);
        String contactName = getContactName(expansionContact, account);
        
		Opportunity dataOpportunity = createExpansionOpportunity('Data deployment trial for ' + contactName, expansionContact, account);
        
        createTask(dataOpportunity, String.format('Work with {0} to get going with data deployment', new List<Object> { contactName }));
        
        return dataOpportunity.Id;
    }
    
    private static Opportunity createExpansionOpportunity(string opportunityName, Contact expansionContact, Account account) {
       String recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Gearset New Opportunity Process').getRecordTypeId();
        
       Opportunity expansionOpportunity = new Opportunity(
        	Name = opportunityName,
            AccountId = account.Id,
            ContactId = expansionContact != null ? expansionContact.Id : null,
            OwnerId = getSdrOwner(expansionContact),
            RecordTypeId = recordTypeId,
            Type = 'Expansion',
            LeadSource = 'Trialist',
            StageName = 'Discovery',
            CloseDate = System.today() + 30
        );
        
        insert expansionOpportunity;
        
        return expansionOpportunity;
    }
    
    private static Account getAccount(String teamId, String email) {
        LOGGER.info('Getting account for expansion');

        Account account = [SELECT Id, Name, (SELECT Name, Email From Contacts WHERE Email = :email) FROM Account WHERE Gearset_team__r.Gearset_team_id__c = :teamId];

        LOGGER.info('Found an account for expansion {0}', account);
        
        if (account == null) {
            throw new IllegalArgumentException('Could not find account for expansion: ' + teamId);
        }
        
        return account;
    }
    
    private static Contact getContact(List<Contact> contacts) {
        Contact expansionContact = null;
        if (contacts.size() > 0) {
            expansionContact = contacts.get(0);
        }
        
        return expansionContact;
    }
    
    private static String getContactName(Contact contact, Account expansionAccount) {
        return contact != null ? contact.Name : expansionAccount.Name;
    }
    
    private static Id getSdrOwner(Contact expansionContact) {
        List<User> sdrs = [SELECT Id, Name FROM User WHERE UserRole.DeveloperName = 'Sales_Development_Representative' ORDER BY Email];
        if (sdrs.size() == 0) {
            return null;
        }
        
        User potentialNewOwner = expansionContact != null ? LeadAssignmentRules.getRepForLead(expansionContact.Email) : null;

        if (potentialNewOwner == null) {
            Integer expansionsCount = [ SELECT COUNT() FROM Opportunity WHERE Type = 'Expansion' ];
            return sdrs.get(math.mod(expansionsCount, sdrs.size())).Id;
        } else {
            return potentialNewOwner.Id;
        }
    }
    
    private static void createTask(Opportunity trialOpportunity, String subject) {
        Task task = new Task(
            Subject = subject,
            Status = 'Open',
            Priority = 'Normal',
            WhatId = trialOpportunity.Id,
            OwnerId = trialOpportunity.OwnerId,
            ActivityDate = Date.today()
        );
        
        insert task;
    }
}