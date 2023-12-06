global class ASF_QueueNotificationJob implements Schedulable,Database.batchable<AggregateResult>{ 
    global Iterable<AggregateResult> start(Database.batchableContext info){ 
        return new ASF_QueueNotificationIterable(); 
    }      
    global void execute(Database.batchableContext info, List<AggregateResult> s){ 
        
        system.debug('coming here');
    	Map<Id,AggregateResult> mResults = new Map<Id,AggregateResult>(s);
        
        List<Case> scope = [SELECT Id, caseNumber, ownerId,Sub_Type_Text__c,Type_Text__c, Owner.type, Last_Owner_Change_Date__c,BusinessHoursId FROM Case wHERE OwnerId =: mResults.keySet()];
    //Business logic to send notification to Queue owner
        Map<String,List<String>> queueVsCaseLst = new Map<String,List<String>>();
        map<string,case> caseNumberRecordMap = new map<string,case>();
        //DateTime d = system.now();
        //d = d.addMinutes(-30);
        BusinessHours deafultBH = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
        list<string> caseOwnerIdList = new list<string>();
        map<Id,list<cases>> ownerIdCaseListMap = new map<Id,list<Cases>>();

        for(Case cHis : scope){
                                          
            if (cHis.Last_Owner_Change_Date__c != null){
                                                    //check queue timing 
                Id businesHrs = cHis.BusinessHoursId;
                if(String.isBlank(BusinesHrs)){
                    businesHrs = deafultBH.Id;
                }

                Decimal timeInMin = BusinessHours.diff(businesHrs, cHis.Last_Owner_Change_Date__c, System.now())/(1000*60);
                System.debug('@@Last_Owner_Change_Date__c'+cHis.Last_Owner_Change_Date__c);
                //push this to custom labels. 30 should come from custom labels
              if(BusinessHours.isWithin(businesHrs, system.now()) && timeInMin > Integer.valueof(System.label.ASF_Case_In_Queue_Long)){
                    if(queueVsCaseLst.containsKey(cHis.ownerId)){
                        List<String> caseLst = queueVsCaseLst.get(cHis.ownerId);
                        caseLst.add(cHis.CaseNumber);
                        queueVsCaseLst.put(cHis.ownerId,caseLst);
                    }else{
                        queueVsCaseLst.put(cHis.ownerId, new List<String>{cHis.CaseNumber});
                    }
                    caseNumberRecordMap.put(cHis.caseNumber,cHis);
                }
            }
        }
		System.debug('caseNumberRecordMap --> '+caseNumberRecordMap);
        //To get the Queue owner email Id
        Map<String,String> queueVsEmail = new Map<String,String>();
        Map<String,Id> queueEmailUserId = new Map<String,Id>();
        Map<Id,String> queueIdQueueObject = new Map<Id,String>();
        for(Group grp : [SELECT Id, Type, Email, OwnerId ,Name
                         FROM Group 
                         WHERE Type = 'Queue' AND Id IN :queueVsCaseLst.keySet()]){
            system.debug('Queue debug--->'+grp.Email+'----->'+grp.Name);
                            queueVsEmail.put(grp.Id,grp.Email);
            queueIdQueueObject.put(grp.id,grp.Name);
        }

        for(User userObject : [SELECT Id,Email
                         FROM User 
                         WHERE Email in :queueVsEmail.values()]){
            queueEmailUserId.put(userObject.Email,userObject.id);
        }                    

        EmailTemplate emailTemp = [Select id, Subject, Body,htmlvalue From EmailTemplate Where DeveloperName = 'Case_In_Queue_Long'];
        Id orgWideAdressId = [SELECT Id, Address, DisplayName, Purpose, IsAllowAllProfiles, LastModifiedBy.Name FROM OrgWideEmailAddress where DisplayName=:System.Label.ASF_default_no_reply_email_address limit 1].get(0).Id;
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        for(String qId : queueVsCaseLst.keySet()){
            List<String> caseLst = queueVsCaseLst.get(qId);
            String qEmail = queueVsEmail.get(qId);
            String htmlBody = getTableEmailBody(caseLst,caseNumberRecordMap);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Unassigned cases beyond TAT in Queue - '+queueIdQueueObject.get(qId));
            String templateBody = emailTemp.htmlvalue;
            templateBody = templateBody.replaceall('<Queue name>',queueIdQueueObject.get(qId));
            templateBody = templateBody.replaceall('ListofcasestoBeReplaced',htmlBody);
            mail.setHtmlBody(templateBody);
            mail.setOrgWideEmailAddressId(orgWideAdressId);
            Id userid = queueEmailUserId.get(qEmail);
            if (userId != null){
                mail.setTargetObjectId(userid);
            }
            else {
                mail.setToAddresses(new List<String>{qEmail});
            }
            mail.saveAsActivity = false;
            emailList.add(mail);
        }

        if(!emailList.isEmpty()){
            if(!Test.IsRunningTest()){
                Messaging.sendEmail(emailList,false);
            }
        }	
          
    }      
    public void finish(Database.batchableContext info){     
    } 
    public static string getTableEmailBody(List<String> caseList,map<string,case> caseNumberRecordMap){

        String htmlBody = '';
        htmlBody = '<table border="1" style="border-collapse: collapse"><thead><th style="padding:5px;">Case Number</th><th style="padding:5px;">Type</th><th style="padding:5px;">Sub Type</th><th style="padding:5px;">Assigned Date & Time</th></thead><tbody>';    
        for(String caseNumber : caseList){   
            case currentRecord =  caseNumberRecordMap.get(caseNumber);

            htmlBody += '<tr><td style="padding: 5px;">' + currentRecord.CaseNumber + '</td>';
            htmlBody += '<td style="padding: 5px;">' + string.valueOf(currentRecord.Type_Text__c) + '</td>';
            htmlBody += '<td style="padding: 5px;">' + string.valueOf(currentRecord.Sub_Type_Text__c)  + '</td>';
            htmlBody += '<td style="padding: 5px;">' + currentRecord.Last_Owner_Change_Date__c.format('MM-dd-yyyy HH:mm:ss', 'IST') + '</td></tr>';
        }
        htmlBody += '</tbody></table>';    
        return htmlBody;
    
    }


    global void execute(SchedulableContext scon) {
        Database.executeBatch(new ASF_QueueNotificationJob(),100);
    }
    
}