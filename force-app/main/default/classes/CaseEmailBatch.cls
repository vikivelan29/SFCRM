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
'00265865',
'00266131',
'00266126',
'00266147',
'00265858',
'00265749',
'00265601',
'00266016',
'00266402',
'00266028',
'00266100',
'00265920',
'00266575',
'00265895',
'00266092',
'00266946',
'00266711',
'00266498',
'00266643',
'00266474',
'00266774',
'00266571',
'00267038',
'00266449',
'00266491',
'00267195',
'00267442',
'00267223',
'00267435',
'00267534',
'00266718',
'00266719',
'00266874',
'00267620',
'00267497',
'00266792',
'00267204',
'00266991',
'00267166',
'00267690',
'00267485',
'00267173',
'00267865',
'00267386',
'00267849',
'00267926',
'00267939',
'00267747',
'00267968',
'00267924',
'00267777',
'00267992',
'00267916',
'00267979',
'00268348',
'00268218',
'00309766',
'00314749',
'00312415',
'00312515',
'00313298',
'00312642',
'00313671',
'00313108',
'00312674',
'00313117',
'00313683',
'00313617',
'00314260',
'00313644',
'00314315',
'00314382',
'00314400',
'00313815',
'00314314',
'00314989',
'00315118',
'00315270',
'00315230',
'00315315',
'00315248',
'00318389',
'00316746',
'00317600',
'00317889',
'00317759',
'00318369',
'00317534',
'00318790',
'00317658',
'00317654',
'00317734',
'00318196',
'00317537',
'00317635',
'00317732',
'00318544',
'00317940',
'00318666',
'00318018',
'00317892',
'00318652',
'00318486',
'00318716',
'00318894',
'00318860',
'00318948',
'00318712',
'00318761',
'00319690',
'00322260',
'00322316',
'00324911',
'00323933',
'00324212',
'00324111',
'00323950',
'00324700',
'00324433',
'00324642',
'00324876',
'00324829',
'00325231',
'00325280',
'00325442',
'00325540',
'00327939',
'00325715',
'00327400',
'00327334',
'00327393',
'00327519',
'00327376',
'00327781',
'00327595',
'00327724',
'00327459',
'00328015',
'00327702',
'00327473',
'00328307',
'00328791',
'00327904',
'00328167',
'00328270',
'00328874',
'00329087',
'00328362',
'00328331',
'00329104',
'00329155',
'00329128',
'00329452',
'00328807',
'00329575',
'00329202',
'00329351',
'00329021',
'00329716',
'00329764',
'00329794',
'00329524',
'00329706',
'00329399',
'00329461',
'00329500',
'00329973',
'00333401',
'00333603',
'00333706',
'00334111',
'00333666',
'00334055',
'00334060',
'00333905',
'00334009',
'00334572',
'00334041',
'00333948',
'00334216',
'00334023',
'00334152',
'00334987',
'00334512',
'00335903',
'00334399',
'00335008',
'00335002',
'00334784',
'00334727',
'00335689',
'00334593',
'00334799',
'00335934',
'00334649',
'00335620',
'00335582',
'00334796',
'00334847',
'00336006',
'00335005',
'00336463',
'00336538',
'00336154',
'00336325',
'00335940',
'00336520'};
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
