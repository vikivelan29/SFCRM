Public class CaseEmailBatch implements Database.batchable<sObject>{

public Database.queryLocator start(Database.BatchableContext bc){
    List<String> caseNumberList = new List<String>{'00176414',
'00188511',
'00195961',
'00198374',
'00199394',
'00201323',
'00202270',
'00204922',
'00207347',
'00208111',
'00212018',
'00214536',
'00216335',
'00217997',
'00219391',
'00221944',
'00226275',
'00226508',
'00227850',
'00227796',
'00227816',
'00227808',
'00228403',
'00227827',
'00227572',
'00227880',
'00227628',
'00228049',
'00228010',
'00229097',
'00229405',
'00235425',
'00235048',
'00241076',
'00241160',
'00241857',
'00241169',
'00241593',
'00241161',
'00241567',
'00242138',
'00241423',
'00241559',
'00241214',
'00242039',
'00241819',
'00241600',
'00241208',
'00241956',
'00242194',
'00242323',
'00242321',
'00241877',
'00242004',
'00242243',
'00242383',
'00242325',
'00242339',
'00242564',
'00242430',
'00247920',
'00247982',
'00248060',
'00247930',
'00248788',
'00248424',
'00248495',
'00248702',
'00249030',
'00248859',
'00249027',
'00249091',
'00249097',
'00256590',
'00256216',
'00256623',
'00257240',
'00257954',
'00258527',
'00259316',
'00264833',
'00265047',
'00265322',
'00265380',
'00265162',
'00265651',
'00265407',
'00265666',
'00266037',
'00265303',
'00265630',
'00265351',
'00266154',
'00265865','00266131','00266126','00266147','00265858','00265749','00265601'};
	String queryString = 'SELECT Id, AccountId, Subject, CaseNumber,Account.PersonContact.Email,Account.PersonContactId,account.recordtype.developername FROM Case WHERE CaseNumber in :caseNumberList';
	return Database.getQueryLocator(queryString); 
}

public void execute(Database.BatchableContext bc, List<Case> cases){
	Set<ID> accIds = new Set<ID>();
	for (Case c : cases) {
    		if (c.AccountId != null) {
        		accIds.add(c.AccountId);
    		}
	}

	// Retrieve accounts based on the collected IDs
	List<Account> accList = [SELECT Id, PersonEmail,PersonContact.Email,recordtype.developerName,(select id,email from contacts) FROM Account WHERE Id IN :accIds];

	// Create a map for Account IDs to emails
	Map<Id, String> accEmailsMap = new Map<Id, String>();
	for (Account acc : accList) {
		if(acc.recordtype.developerName == 'Individual')
		{
            if (acc.PersonEmail != null && !accEmailsMap.containsKey(acc.Id)) {
                accEmailsMap.put(acc.Id, acc.PersonEmail);
            }
		}
		if(acc.recordtype.developerName == 'Non_Individual')
		{
            if (acc.contacts[0] != null && acc.contacts[0].Email != null && !accEmailsMap.containsKey(acc.Id)) {
                accEmailsMap.put(acc.Id, acc.contacts[0].Email);
            }
		}
	}

	List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

	// Retrieve the email template
	EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'apologize_email_to_customer_1726208031855' LIMIT 1];
    
	List<User> userList = [Select id,name from user where name = 'ABFSGSFDC User'];    
	List<ABFL_Case_Detail__c> abflCase = new List<ABFL_Case_Detail__c>();
	    Id abflId;
	    if(cases.size()> 0 ){
	        if(cases[0].ABFL_Case_Detail__c != null){
	            abflCase = [Select Id, Resolution_Comments__c from ABFL_Case_Detail__c Where ID =: cases[0].ABFL_case_Detail__c Limit 1];    
	            if(abflCase.size()>0){
	                abflId = abflCase[0].Id;
	                abflCase[0].Resolution_Comments__c = 'Self Service';
	                update abflCase;
	            }
	        } else{
	            abflCase.add(new ABFL_Case_Detail__c(Resolution_Comments__c = 'Self Service'));
	            insert abflCase;
	            abflId = abflCase[0].Id;
	            System.debug('abflID ' + abflId);
	        }
	    }

    for(Case c : cases){
        c.Status = 'Resolved';
	c.Stage__c = 'Resolved';
	c.ABFL_Case_Detail__c = abflCase[0].Id;
        c.Resolution_Comments__c = 'Self Service';
        c.ownerId = userList[0].Id;
    }
    update cases;

    for (Case c : cases) {
        if (accEmailsMap.containsKey(c.AccountId)) {
        	
        	Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            //String orgWideEmailAddrId = 'abctsl.crmteam-noreply@adityabirlacapital.com'; 
        	OrgWideEmailAddress orgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'abctsl.crmteam-noreply@adityabirlacapital.com' LIMIT 1];

            // Get the ID
            Id orgWideEmailAddrId = orgWideEmail.Id;
            System.debug('emailTemplate ' + emailTemplate.Id);
            System.debug('HTML ' + emailTemplate.HtmlValue);
            email.setHtmlBody(emailTemplate.HtmlValue);        
            email.setSubject('Self Service Option');
            email.setOrgWideEmailAddressId(orgWideEmailAddrId);
        	email.setToAddresses(new List<String>{ accEmailsMap.get(c.AccountId) });
            if(c.account.recordtype.developername == 'Individual'){
            	email.setTargetObjectId(c.Account.PersonContactId);    
            }
            if(c.account.recordtype.developername == 'Non_Individual'){
                String contactId;
                for(Account acc : accList){
                    if(c.AccountId == acc.id){
                        contactId = acc.contacts[0].id;
                    }
                }
            	email.setTargetObjectId(contactId);    
            }
        	
        	email.setWhatId(c.Id);
		System.debug('Email: ' + email);
            	System.debug('Actual Email Body '+ email.getHtmlBody());
        	emailsToSend.add(email);
        }
    }    
    
	if (!emailsToSend.isEmpty()) {
    	List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailsToSend, false);
	}
}

public void finish(Database.BatchableContext bc){
    
}    

}
