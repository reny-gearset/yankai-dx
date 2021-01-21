public without sharing class CsmAssignment {
    private static UserRole csmRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Customer_Success_Manager'];
    
    public static Id assigneeForNewRenewalOpp(Account accountForOpp) {
        List<User> csms = [SELECT Id FROM User WHERE UserRoleId = :csmRoleId.Id ORDER BY Email];
        Boolean currentAccountOwnerIsACsm = isUserInList(accountForOpp.OwnerId, csms);
        
        if (currentAccountOwnerIsACsm) {
            return accountForOpp.OwnerId;
        }
        
        Integer numCsmdOpps = [SELECT Count() FROM Opportunity WHERE Owner.UserRoleId = :csmRoleId.Id AND RecordType.DeveloperName = 'Gearset_Renewals_Process'];
        
        return csms[Math.mod(numCsmdOpps, csms.size())].Id;
    }
    
    public static void handleWonOpportunity(Opportunity wonOp) {
        Account accountForOp = [SELECT Id, Name, OwnerId, Churn_Risk__c FROM Account WHERE Id = :wonOp.AccountId];
                        
        if (wonOp.Amount >= 1000) {
            List<User> csms = [SELECT Id FROM User WHERE UserRoleId = :csmRoleId.Id ORDER BY Email];
            Boolean currentAccountOwnerIsACsm = isUserInList(accountForOp.OwnerId, csms);

            if (currentAccountOwnerIsACsm) {
                insert new Task(
                    Subject = String.format('Meatball opportunity just closed for {0}', new List<Object> { accountForOp.Name }),
                    Description = descriptionForOpportunity(wonOp),
                    WhatId = accountForOp.Id,
                    OwnerId = accountForOp.OwnerId,
                    ActivityDate = Date.today()
                );
                return;
            }
            
            assignAccountToCsm(accountForOp, csms, wonOp);
        } else {           
            if (accountForOp.churn_risk__c == null) {
                accountForOp.churn_risk__c = 'Ramped';
            }
            update accountForOp;
        }
    }
    
    private static void assignAccountToCsm(Account accountForOp, List<User> csms, Opportunity wonOp) {
        Integer numManagedAccounts = [SELECT COUNT() FROM Account WHERE Owner.UserRoleId = :csmRoleId.Id];
        User currentOpOwner = [SELECT Id, Name FROM User WHERE Id = :wonOp.OwnerId];
        
        Id newAccountOwnerId = csms.get(Math.mod(numManagedAccounts, csms.size())).Id;
        accountForOp.OwnerId = newAccountOwnerId;
        accountForOp.churn_risk__c = 'Onboarding';
        
        update accountForOp;
        
        insert new Task(
        	Subject = 'Handover for new meatball account',
            WhatId = accountForOp.Id,
            OwnerId = newAccountOwnerId,
            Description = String.format('Handover from {0} about account {1}. {2}', new List<Object> { 
                currentOpOwner.Name,
                accountForOp.Name,
                descriptionForOpportunity(wonOp)
            }),
            ActivityDate = Date.today()
        );
    }
    
    private static String descriptionForOpportunity(Opportunity o) {
        return String.format('Opportunity {0} with MRR ${1} just closed. {2}', new List<Object>{
            o.Name,
            o.Amount,
            URL.getSalesforceBaseUrl().toExternalForm()+'/'+o.Id
        });
    }
    
    private static Boolean isUserInList(Id userId, List<User> users) {
        for (User user : users) {
            if (user.Id == userId) {
                return true;
            }
        }
        
        return false;
    }
}