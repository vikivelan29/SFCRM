/*********************************************************
*@Class        :  ABHFL_CTSTHelper
*@Author       :  Dhinesh Kumar T
*@Created Date :  12/25/2023
*@Last Modified:  01/11/2024
*@description  :  Class for ABHFL Specific Methods. 
*********************************************************/
public without sharing class ABHFL_CTSTHelper {

    //static variables to skip repeatitive query in single transaction
    private static Map<Id, List<ABHFL_Payment__c>> paymentsMapStatic = new Map<Id, List<ABHFL_Payment__c>>();
    
    //AM-Delete existing asset detail records on a case on customer change
    public static void deleteExistingAssetDetails(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        Set<Id> caseIds = new Set<Id>();
        Map<Id, List<ABHFL_Asset_Detail__c>> caseAssetDetailMap = new Map<Id, List<ABHFL_Asset_Detail__c>>();
        List<ABHFL_Asset_Detail__c> assetDetailsToDelete = new List<ABHFL_Asset_Detail__c>();
        for(Case cs: newCaseList){
            if(cs.Business_Unit__c=='ABHFL'){
            	caseIds.add(cs.Id);    
            }
        }
        for(ABHFL_Asset_Detail__c assetDetail :[SELECT Id, Case__c FROM ABHFL_Asset_Detail__c WHERE Case__c IN :caseIds])
        {
            if(!caseAssetDetailMap.containsKey(assetDetail.Case__c)){
                caseAssetDetailMap.put(assetDetail.Case__c, new List<ABHFL_Asset_Detail__c>());
            }
       		caseAssetDetailMap.get(assetDetail.Case__c).add(assetDetail);
        }
        if(caseIds!=null){
           	for(Case c: newCaseList){
                if(caseAssetDetailMap.get(c.Id)!=null && c.AccountId!=null && oldCaseMap.get(c.Id).AccountId != c.AccountId)
                {
                    assetDetailsToDelete.addAll(caseAssetDetailMap.get(c.Id));
                }
            } 
        }
        if(assetDetailsToDelete!=null){
            try{
                delete assetDetailsToDelete;
            }catch(Exception ex){
                system.debug('Exception message:'+ex.getMessage());
            }
        }
    }
    
    //AM-SLA broken reset change on Open --> In Progress for Complaints
    public static void updateSlaBrokenCheckOnStageMovement(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case c: newCaseList){
            if(c.Business_Unit__c =='ABHFL' && c.SLA_Broken__c == true && c.SLA_Broken_DateTime__c!=null &&
              	c.Stage__c== 'In Progress' && oldCaseMap.get(c.Id).Stage__c == 'Open' && 
               	ABHFL_Constants.SLA_Broken_Reset_CCC_List.split(',').contains(c.CCC_External_Id__c))
            {
           		c.SLA_Broken__c = false;
                c.SLA_Broken_DateTime__c = null;
           	}
        }
    }
    
    //AM-PR970457-1295-Send Grievance Officer mail
    public static void sendGrievanceDetailsEmail(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
          
        Map<String, ABHFL_Case_Detail__c> caseToDetailMap = new Map<String,ABHFL_Case_Detail__c>();
        Map<String, User> ownerMap = new Map<String,User>();
        Set<String> caseDetailIds = new Set<String>();
        Set<String> ownerIds = new Set<String>();
        List<Case> casesForCreatePELogAndinvokeCommPEevent = new List<Case>();
        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        List<ABHFL_Case_Detail__c> caseDetailList = new List<ABHFL_Case_Detail__c>();
        
        for(Case caseRec : newCaseList){
            if(caseRec.Business_Unit__c=='ABHFL'){
            	caseDetailIds.add(caseRec.ABHFL_Case_Detail__c);
                ownerIds.add(caseRec.OwnerId);
            }
        }
        
        for(ABHFL_Case_Detail__c cd : [SELECT Id, Grievance_Details_Sent__c FROM ABHFL_Case_Detail__c WHERE Id IN :caseDetailIds]){
            caseToDetailMap.put(cd.Id, cd);
        }
        for(User us : [SELECT Id, Assigned_Team__c FROM User WHERE Id IN :ownerIds]){
            ownerMap.put(us.Id, us);
        }
        
        if(!caseDetailIds.isEmpty()){
            List<EmailTemplate> grievanceEmailTemplate = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE Name='Grievance Details In InProgress Stage' LIMIT 1];
            for(Case c: newCaseList){
                //system.debug('ownerMap.get(c.OwnerId).Assigned_Team__c:'+ownerMap.get(c.OwnerId).Assigned_Team__c);
                //if(ownerMap.get(c.OwnerId)!=null){
                	if(caseToDetailMap.get(c.ABHFL_Case_Detail__c)!=null && ownerMap.get(c.OwnerId)!=null &&
                       ownerMap.get(c.OwnerId).Assigned_Team__c!=null &&
                       !caseToDetailMap.get(c.ABHFL_Case_Detail__c).Grievance_Details_Sent__c && c.Stage__c=='In Progress' 
                       && ownerMap.get(c.OwnerId).Assigned_Team__c.contains('Grievance'))
                            /*&& (oldCaseMap.get(c.Id).OwnerId != c.OwnerId) && (c.OwnerId!=null && String.valueOf(c.OwnerId).startsWith('005'))
                            && (oldCaseMap.get(c.Id).OwnerId!=null && String.valueOf(oldCaseMap.get(c.Id).OwnerId).startsWith('00G') /*&& oldCaseMap.get(c.Id).Owner.Name=='ABHFL Grievance'))*/
                    {
                        casesForCreatePELogAndinvokeCommPEevent.add(c);
                        emailTemplateMap.put(c.Id, grievanceEmailTemplate[0].DeveloperName);
                        isTransferredMap.put(c.Id,true);
                        caseToDetailMap.get(c.ABHFL_Case_Detail__c).Grievance_Details_Sent__c = true;
                        caseDetailList.add(caseToDetailMap.get(c.ABHFL_Case_Detail__c));
                    }    
                //}
               	
            }
        }
        if(!casesForCreatePELogAndinvokeCommPEevent.isEmpty()){
           	ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(casesForCreatePELogAndinvokeCommPEevent,emailTemplateMap, smsMetadataMap, isTransferredMap);
       	}
        if(!caseDetailList.isEmpty()){
            update caseDetailList;
        }
    }
    
    public static void runDuplicateCheck(List<Case> caseList){//AM-ABHFL Case DEDUPE
        
        List<ASF_Case_Category_Config__c> caseCategoryConfigs = new List<ASF_Case_Category_Config__c>();
        Map<String, List<Case>> accIdVsCases = new Map<String, List<Case>>();
        Map<String, List<Case>> lanVsCases = new Map<String, List<Case>>();
        Map<String,Set<String>> cccVsAccIds = new Map<String,Set<String>>();
        Set<String> cccIds = new Set<String>();
        for(Case c: caseList){
            if(c.AccountId!=null && 
               	c.CCC_External_Id__c!=null && 
               	c.AssetId!=null &&
                c.CCC_External_Id__c!='qbccdd01')
            {
                if((!accIdVsCases.containsKey(c.AccountId))){
                   	accIdVsCases.put(c.AccountId, new List<Case>());
                }
                accIdVsCases.get(c.AccountId).add(c);
                
                
                if(!cccVsAccIds.containsKey(c.CCC_External_Id__c)){
                    cccVsAccIds.put(c.CCC_External_Id__c, new Set<String>());
                }
                cccVsAccIds.get(c.CCC_External_Id__c).add(c.AccountId);
                    

                if((!lanVsCases.containsKey(c.AssetId))){
                    lanVsCases.put(c.AssetId, new List<Case>());
                }
                lanVsCases.get(c.AssetId).add(c);
            }
		}
        
        caseCategoryConfigs = [SELECT ID,Type__c, Sub_Type__c,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =: cccVsAccIds.keySet()];
        
        for(ASF_Case_Category_Config__c ccc : caseCategoryConfigs){
            cccIds.add(ccc.CCC_External_Id__c);
        }
        for(Case dupeCase: [SELECT Id, Sub_Type_Text__c, SLA_Broken_DateTime__c, Overall_Case_Closure_SLA__c, CaseNumber, AccountId, CCC_External_Id__c, AssetId
                           	FROM Case 
                            WHERE (AccountId IN :accIdVsCases.keySet())
                           	AND CCC_External_Id__c IN :cccVsAccIds.keySet()
                           	AND (AssetId IN :lanVsCases.keySet())
                           	AND isClosed!=true])
        {
            if(cccIds.contains(dupeCase.CCC_External_Id__c)){
                if(accIdVsCases.containsKey(dupeCase.AccountId)){
                    for(Case c: accIdVsCases.get(dupeCase.AccountId)){
                        if(lanVsCases.containsKey(c.AssetId)){
                            String overallCaseClosureSLA = (dupeCase.Overall_Case_Closure_SLA__c != null) ? (dupeCase.Overall_Case_Closure_SLA__c.format('dd/MM/yyyy hh:mm:ss a','IST')) : '';
                            if(dupeCase.SLA_Broken_DateTime__c!=null){
                                c.addError('Existing case available in CRM#'+dupeCase.CaseNumber+',CaseSubType#'+dupeCase.Sub_Type_Text__c+',ResolutionDate#'+overallCaseClosureSLA+',CASESTATUS#Active,TATSTATUS#Outside TAT');
                            }else{
                                c.addError('Existing case available in CRM#'+dupeCase.CaseNumber+',CaseSubType#'+dupeCase.Sub_Type_Text__c+',ResolutionDate#'+overallCaseClosureSLA+',CASESTATUS#Active,TATSTATUS#Within TAT');  
                            }
                        }
					}
                }
            }
        }
    }
    
    public static void runDuplicateCheckForUpdate(List<Case> caseList, Map<Id, Case> oldCaseMap){//AM-ABHFL Case DEDUPE
        List<ASF_Case_Category_Config__c> caseCategoryConfigsForAcc = new List<ASF_Case_Category_Config__c>();
        Map<String, List<Case>> accIdVsCases = new Map<String, List<Case>>();
        Map<String, List<Case>> lanVsCases = new Map<String, List<Case>>();
        Map<String,Set<Id>> cccVsAccIds = new Map<String,Set<Id>>();
	Set<String> cccIdsForAcc = new Set<String>();
	Map<Id,Case> IdvsCase = new Map<Id,Case>();            // added by vikas
	Map<Id, Case> casesToUpdate = new Map<Id, Case>();    
        RecordType InteractionRecType = [select id,Name, SobjectType from RecordType where Name='Interaction' and SobjectType ='Case' LIMIT 1];
        for(Case c: caseList){
		IdvsCase.put(c.Id,c);                            // added by vikas
            if(c.Business_Unit__c=='ABHFL' && 
               		(c.CCC_External_Id__c != oldCaseMap.get(c.Id).CCC_External_Id__c ||
                	c.AccountId != oldCaseMap.get(c.Id).AccountId ||
                	c.AssetId != oldCaseMap.get(c.Id).AssetId))
            {
                if((c.AccountId!=null) && 
                    c.CCC_External_Id__c!=null && 
                    (c.AssetId!=null) && 
                    c.CCC_External_Id__c!='qbccdd01' && 
                    c.Source__c=='Email'
                    )
            	{                
                    if((!accIdVsCases.containsKey(c.AccountId))){
                       	accIdVsCases.put(c.AccountId, new List<Case>());
                    }
                    accIdVsCases.get(c.AccountId).add(c);
                    
                    
                    if(!cccVsAccIds.containsKey(c.CCC_External_Id__c)){
                        cccVsAccIds.put(c.CCC_External_Id__c, new Set<Id>());
                    }
                    cccVsAccIds.get(c.CCC_External_Id__c).add(c.AccountId);
                    
                    
                    if((!lanVsCases.containsKey(c.AssetId))){
                       	lanVsCases.put(c.AssetId, new List<Case>());
                    }
                    lanVsCases.get(c.AssetId).add(c);
                }
            }
        }
        
        
        if(!cccVsAccIds.isEmpty()){
        	caseCategoryConfigsForAcc = [SELECT ID,Type__c, Sub_Type__c,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =: cccVsAccIds.keySet()];    
            for(ASF_Case_Category_Config__c ccc : caseCategoryConfigsForAcc){
                cccIdsForAcc.add(ccc.CCC_External_Id__c);
            }
        }
        	
        
        if(!cccVsAccIds.isEmpty()){
        	for(Case dupeCase: [SELECT Id, Sub_Type_Text__c, SLA_Broken_DateTime__c, Overall_Case_Closure_SLA__c, CaseNumber, AccountId, CCC_External_Id__c, AssetId
                                FROM Case 
                                WHERE (AccountId IN :accIdVsCases.keySet())
                                AND CCC_External_Id__c IN :cccVsAccIds.keySet()
                                AND (AssetId IN :lanVsCases.keySet())
                                AND isClosed!=true])
            {
                if(cccIdsForAcc.contains(dupeCase.CCC_External_Id__c)){
                    if(accIdVsCases.containsKey(dupeCase.AccountId)){
                        for(Case c: accIdVsCases.get(dupeCase.AccountId)){
                            if(lanVsCases.containsKey(c.AssetId)){
				if(c.Is_Recategorise_Allowed__c && c.CCC_External_Id__c != oldCaseMap.get(c.Id).CCC_External_Id__c ){
                                ASF_CaseTriggerModularHelper.invokeSLACalculationMethods(IdvsCase,oldCaseMap); 
				}                                                                                // added by vikas, After recategorisation, ovarall SLA should changed before marked as closed duplicate.
                                if(c.Skip_Dedupe__c && oldCaseMap.get(c.Id).RecordTypeId==InteractionRecType.Id){
                                    c.Stage__c = ASF_Constants.DUPLICATESTAGE;
                                    c.Status = ASF_Constants.DUPLICATESTATUS;
                                    c.Rejected_Reason__c = 'Duplicate Case';
                                    c.Is_Duplicate__c = true;
                                    c.ParentId = dupeCase.Id;
                                }else if(!c.ABHFL_Case_Detail__r.Skip_Dedupe__c){
                                    c.Stage__c = ASF_Constants.DUPLICATESTAGE;
                                    c.Status = ASF_Constants.DUPLICATESTATUS;
                                    c.Rejected_Reason__c = 'Duplicate Case';
                                    c.Is_Duplicate__c = true;
                                    c.ParentId = dupeCase.Id;
                                }
                            }
                        }
                    }
                }
            }    
        }
    }
    
    //Dhinesh
    public static void OpenStageOwnershipChange(List<Case> caseList, Map<Id, Case> oldCaseMap) {
    // List of valid subTypes
    	List<String> validSubTypes = new List<String>{'hfl060', 'RRSDPRSHFC01','hfcrepaprod','RREPEMIONHFC','ROVEOVSSHFC','hfl029','AC123470','HFCRARGI'};

    	for (Case caseRecord : caseList) {
        	Case originalCase = oldCaseMap.get(caseRecord.Id);

        	String previousStage = originalCase.Stage__c;	
        	String currentStage = caseRecord.Stage__c;
        	String subType = caseRecord.CCC_External_Id__c;

        // Check if the previous stage was not 'Open', the current stage is 'Open',
        // and the sub_Type_Text__c is one of the valid subTypes
        	if (!'Open'.equals(previousStage) && 'Open'.equals(currentStage) && validSubTypes.contains(subType) && caseRecord.Business_Unit__c == 'ABHFL' && caseRecord.RecordTypeId == ASF_Constants.RT_FRAMEWORK) {
            	assignCaseToQueue(caseRecord);
        	}
    	}
	}

    //Called from OpenStageOwnershipChange
    public static void assignCaseToQueue(Case caseRecord) {
    	String subType = (String)caseRecord.get('CCC_External_Id__c');
        String ownerName = '';
        Case caseRec = [SELECT Id,Source__c,CreatedBy.Name,CreatedById from Case where id =: caseRecord.id];
    	List<String> emailFinancialSubTypes = new List<String>{'hfcrepaprod','RREPEMIONHFC','ROVEOVSSHFC','hfl029','hfl060'};
    	List<String> emailNonFinancialSubTypes = new List<String>{'AC123470','HFCRARGI'}; 
        //List<String> customerServiceSubTypes = new List<String>{'hfl060'};
    	Group emailNonFinancialQueue = [SELECT Id,Name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Email_Non_Financial_Team' WITH SECURITY_ENFORCED LIMIT 1];
    	Group emailFinancialQueue = [SELECT Id,Name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Email_Financial_Team' WITH SECURITY_ENFORCED LIMIT 1];
       // Group customerServiceQueue = [SELECT Id,Name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' WITH SECURITY_ENFORCED LIMIT 1];
		// Create a new instance to avoid trigger recursion
   	 	Case updatedCase = new Case(Id = caseRecord.Id);
		// assign the case to a queue 
    	if (emailNonFinancialSubTypes.contains(subType)) {
        	if (caseRec.Source__c == ABHFL_Constants.BRANCH) {
            updatedCase.OwnerId = caseRec.CreatedById;
            ownerName = caseRec.CreatedBy.Name;
        	} else {
            updatedCase.OwnerId = emailNonFinancialQueue.Id;
            ownerName = emailNonFinancialQueue.Name;
        	}
    	}

    	if (emailFinancialSubTypes.contains(subType)) {
        	if (caseRec.Source__c == ABHFL_Constants.BRANCH) {
            updatedCase.OwnerId = caseRec.CreatedById;
            ownerName = caseRec.CreatedBy.Name;
        	} else {
            updatedCase.OwnerId = emailFinancialQueue.Id;
            ownerName = emailFinancialQueue.Name;
        		}
    	}
        /*if (customerServiceSubTypes.contains(subType)) {
        	if (caseRec.Source__c == ABHFL_Constants.BRANCH) {
            updatedCase.OwnerId = caseRec.CreatedById;
            ownerName = caseRec.CreatedBy.Name;
        	} else {
            updatedCase.OwnerId = customerServiceQueue.Id;
            ownerName = customerServiceQueue.Name;
        		}
    	}*/

    	if (subType == 'RRSDPRSHFC01') {
        	updatedCase.OwnerId = emailFinancialQueue.Id;
            ownerName = emailFinancialQueue.Name;
    	}
        if(updatedCase.OwnerId != null){
            Map<Integer,ASF_SLABusinessHoursWrapper> slaTargetEmailMap = ASF_CaseSLAHandlerV1.getOwnerHierarchy(new List<Case>{updatedCase}, new List<String>(), new List<String>{updatedCase.OwnerId});
            if(slaTargetEmailMap != null){
                ASF_SLABusinessHoursWrapper wrapper = slaTargetEmailMap.get(0);
                if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord != null){
                    if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager != null){
                        updatedCase.SLA_Target_1__c = wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.email;
                    }
                    if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager != null){
                        updatedCase.SLA_Target_2__c = wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.email;
                    }
                    if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.manager != null){
                        updatedCase.SLA_Target_3__c = wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.manager.email;
                    }
                }
            }
        }
        List<ASF_Case_SLA_History__c> slaHistory = [SELECT Id, Current_Owner_Id__c,Current_Owner__c   FROM ASF_Case_SLA_History__c WHERE Case__c = :caseRecord.Id AND Stage_End_Date__c = NULL Order By CreatedDate Desc LIMIT 1];

    	if (slaHistory.size() > 0) {
            slaHistory[0].Current_Owner_Id__c = updatedCase.OwnerId;
            if(ownerName != ''){
                slaHistory[0].Current_Owner__c = ownerName;
            }
            
        	update slaHistory;
    	}
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
    	update new List<Case>{ updatedCase };
		ASF_TriggerSkipperUtility.resetTriggerRun('Case');
	}

    //Dhinesh - Stop at banking stage on forward movement after a backward movement.
    public static void preClosureStopAtCPUBanking(List<Case> caseList, Map<Id, Case> oldCaseMap) {
        // List of valid subTypes
    	List<String> validSubTypes = new List<String>{'qbccdd01', 'hfl060','RRSDPRSHFC01'};
        
    	for (Case caseRecord : caseList) {
        	Case originalCase = oldCaseMap.get(caseRecord.Id);

        	String previousStage = originalCase.Stage__c;	
        	String currentStage = caseRecord.Stage__c;
        	String subType = caseRecord.CCC_External_Id__c;
            system.debug(caseRecord.moved_back__c);
    

        // Check if the previous stage was 'Open', the current stage is not 'Open',
        // and the sub_Type_Text__c is one of the valid subTypes
        	if ('Open'.equals(previousStage) && !'Open'.equals(currentStage) && validSubTypes.contains(subType) && caseRecord.moved_back__c == TRUE && caseRecord.Business_Unit__c == 'ABHFL' && caseRecord.RecordTypeId == ASF_Constants.RT_FRAMEWORK) {
            	changeStagetoCPUBanking(caseRecord);
                ASF_CaseTriggerModularHelper.preClosureStageAlreadyStamped = true;
        	}
            
    	}
	}
    
    public static void changeStagetoCPUBanking(Case caseRecord) {
        Group CPUQueue = [SELECT Id,Name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_CPU_Banking_Team' WITH SECURITY_ENFORCED LIMIT 1];
        caseRecord.Stage__c ='CPU Banking';
        caseRecord.Status ='In Progress';
        caseRecord.OwnerId = CPUQueue.Id;
    }
    //Dhinesh
    public static Map<Id, Case> assignCaseToBranch(List<Case> caseRecords) {
        
        Map<Id, Case> updatedCasesMap = new Map<Id, Case>();
        for(Case caseRec : caseRecords){
            if (caseRec.Asset.Branch__r.Branch_Queue_Id__c != null && caseRec.Source__c != 'Branch') {
                Case blankCase = new Case(Id = caseRec.Id);
                blankCase.OwnerId = caseRec.Asset.Branch__r.Branch_Queue_Id__c;
                updatedCasesMap.put(blankCase.Id, blankCase);
            }
        }
        return updatedCasesMap;
    }
    //Dhinesh
   public static Map<Id, Case> assignCaseToPreferredBranch(List<Case> caseRecords) {
        //Case caseRec = [SELECT Id, OwnerId,ABHFL_Case_Detail__c FROM Case WHERE Id = :caseRecord.Id WITH SECURITY_ENFORCED];
        //ABHFL_Case_Detail__c caseDetail = [SELECT Id,Preferred_Branch__c FROM ABHFL_Case_Detail__c WHERE Id =:caseRec.ABHFL_Case_Detail__c LIMIT 1];

        List<Case> eligibleCases = new List<Case>();
        Map<String, Id> uniqueKeyToCaseId = new Map<String, Id>();
        for(Case caseRec : caseRecords){
            eligibleCases.add(caseRec);
            uniqueKeyToCaseId.put(caseRec.ABHFL_Case_Detail__r.Preferred_Branch__c, caseRec.Id);
        }
        Map<Id, Case> updatedCasesMap = new Map<Id, Case>();
        List<ABHFL_Case_Detail__c> caseDetailsToUpdate = new List<ABHFL_Case_Detail__c>();
        Set<ID>activeuserlst=new set<ID>(); 
        for(User u: [Select Id from user where Isactive=true]){
            activeuserlst.add(u.Id);
        }
        Id queuewhennospoc=[Select Id,Name from Group where type='Queue' AND Name='Unassigned Queue'].Id;
        if(!eligibleCases.isEmpty()){
            Map<Id, Branch_Master__c> caseIdToBranchMap = new Map<Id, Branch_Master__c>();
            for(Branch_Master__c branch : [SELECT Id,Branch_Queue_Id__c,Address__c, UniqueKey__c,CRM_SPOC__c FROM Branch_Master__c WHERE UniqueKey__c IN: uniqueKeyToCaseId.keySet()])
            {
                caseIdToBranchMap.put(uniqueKeyToCaseId.get(branch.UniqueKey__c), branch);
            }
            for(Case caseRec : eligibleCases){
               Case blankCase = new Case(Id = caseRec.Id);
                
                if(caseIdToBranchMap.get(caseRec.Id).CRM_SPOC__c != null && activeuserlst.contains(caseIdToBranchMap.get(caseRec.Id).CRM_SPOC__c)){
                        blankCase.OwnerId = caseIdToBranchMap.get(caseRec.Id).CRM_SPOC__c;
                    }
                    else
                    {
                    blankCase.OwnerId=queuewhennospoc;    
                    }
                    updatedCasesMap.put(blankCase.Id, blankCase);
                ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c(Id = caseRec.ABHFL_Case_Detail__c);
                caseDetail.Address__c = caseIdToBranchMap.get(caseRec.Id).Address__c;
                caseDetailsToUpdate.add(caseDetail);
            }
        }
        
        update caseDetailsToUpdate;
        return updatedCasesMap;
    }
    @AuraEnabled
    public static void updateCaseExtension(String caseextensionId, String complainttype){
        ABHFL_Case_Detail__c caseDetail = [SELECT Id,Complaint_Type__c FROM ABHFL_Case_Detail__c WHERE Id =:caseextensionId LIMIT 1];
        caseDetail.Complaint_Type__c = complainttype;
        update caseDetail;
    }
    //Dhinesh - TDS Refund BRANCH assignment
    public static Map<Id, Case> assignCaseToBranchTDS(List<Case> caseRecords) {
        //Case caseRec = [SELECT Id, OwnerId,AssetId,Source__c FROM Case WHERE Id = :caseRecord.Id WITH SECURITY_ENFORCED];
        Boolean emailNonFinancialQueueReqd = false;//To query Group only if relevant case present
        for(Case caseRec : caseRecords){
            if (caseRec.Asset.Branch__r.Branch_Queue_Id__c != null && caseRec.Source__c != 'Branch'){
                emailNonFinancialQueueReqd = true;
                break;
            }
        }
        Group emailNonFinancialQueue;
        if(emailNonFinancialQueueReqd){
            emailNonFinancialQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Email_Non_Financial_Team' WITH SECURITY_ENFORCED LIMIT 1];
        }
        Map<Id, Case> updatedCasesMap = new Map<Id, Case>();
        for(Case caseRec : caseRecords){
            if (caseRec.Asset.Branch__r.Branch_Queue_Id__c != null && caseRec.Source__c == 'Branch') {
                Case blankCase = new Case(Id = caseRec.Id);
                blankCase.OwnerId = caseRec.Asset.Branch__r.Branch_Queue_Id__c;
                updatedCasesMap.put(blankCase.Id, blankCase);
            }
            if (caseRec.Asset.Branch__r.Branch_Queue_Id__c != null && caseRec.Source__c != 'Branch' && emailNonFinancialQueue != null){
                Case blankCase = new Case(Id = caseRec.Id);
                blankCase.OwnerId = emailNonFinancialQueue.Id;
                updatedCasesMap.put(blankCase.Id, blankCase);
            }
        }
        return updatedCasesMap;
    }
    
    
    //Dhinesh - Collateral Doc Case Assignment
    public static Map<Id, Case> assignCaseCollateralDocs(List<Case> caseRecords) {
        //Case caseRec = [SELECT Id, OwnerId,AssetId,Source__c FROM Case WHERE Id = :caseRecord.Id WITH SECURITY_ENFORCED];
		//ABHFL_Case_Detail__c caseDetail = [SELECT Id,CreatedById  FROM ABHFL_Case_Detail__c WHERE Id =:caseRec.ABHFL_Case_Detail__c LIMIT 1];
        Boolean emailNonFinancialQueueReqd = false;
        for(Case caseRec : caseRecords){
            if (caseRec.Source__c != 'Branch'){
                emailNonFinancialQueueReqd = true;
                break;
            }
        }
        Group emailNonFinancialQueue;
        if(emailNonFinancialQueueReqd){
            emailNonFinancialQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Email_Non_Financial_Team' WITH SECURITY_ENFORCED LIMIT 1];
        }
        
        Map<Id, Case> updatedCasesMap = new Map<Id, Case>();
        for(Case caseRec : caseRecords){
            if (caseRec.Source__c == 'Branch') {
                Case blankCase = new Case(Id = caseRec.Id);
                blankCase.OwnerId = caseRec.ABHFL_Case_Detail__r.CreatedById;
                updatedCasesMap.put(blankCase.Id, blankCase);
            }
            if (caseRec.Source__c != 'Branch' && emailNonFinancialQueue != null){
                Case blankCase = new Case(Id = caseRec.Id);
                blankCase.OwnerId = emailNonFinancialQueue.Id;
                updatedCasesMap.put(blankCase.Id, blankCase);
            }
        }
        return updatedCasesMap;
    }
    
    //Dhinesh - Used for assigning case to AOM/ROM
    public static Map<Id, Case> assignCaseToAOMROM(List<Case> caseRecords){
        //Case caseRec = [SELECT Id, OwnerId,ABHFL_Case_Detail__c FROM Case WHERE Id = :caseRecord.Id WITH SECURITY_ENFORCED];
        //ABHFL_Case_Detail__c caseDetail = [SELECT Id,Preferred_Branch__c FROM ABHFL_Case_Detail__c WHERE Id =:caseRec.ABHFL_Case_Detail__c LIMIT 1];
        List<Case> eligibleCases = new List<Case>();
        Map<String, Id> uniqueKeyToCaseId = new Map<String, Id>();
        for(Case caseRec : caseRecords){
            eligibleCases.add(caseRec);
            uniqueKeyToCaseId.put(caseRec.ABHFL_Case_Detail__r.Preferred_Branch__c, caseRec.Id);
        }
        Map<Id, Case> updatedCasesMap = new Map<Id, Case>();
        if(!eligibleCases.isEmpty()){
            Map<Id, Branch_Master__c> caseIdToBranchMap = new Map<Id, Branch_Master__c>();
            for(Branch_Master__c branch : [SELECT Id,Branch_Queue_Id__c, UniqueKey__c, ROM_AOM__c FROM Branch_Master__c WHERE UniqueKey__c IN: uniqueKeyToCaseId.keySet()])
            {
                caseIdToBranchMap.put(uniqueKeyToCaseId.get(branch.UniqueKey__c), branch);
            }
            for(Case caseRec : eligibleCases){
                if(caseIdToBranchMap.get(caseRec.Id).ROM_AOM__c != null){
                    Case blankCase = new Case(Id = caseRec.Id);
                    blankCase.OwnerId = caseIdToBranchMap.get(caseRec.Id).ROM_AOM__c;
                    updatedCasesMap.put(blankCase.Id, blankCase);
                }
                
            }
        }
        return updatedCasesMap;
    }
    
    //Dhinesh
    public static Map<Id, Boolean> validatePayments(List<Case> caseRecords) {
        //Case queriedCase = [SELECT Id FROM Case WHERE Id = :caseRecord.Id LIMIT 1];
        Map<Id, Boolean> returnMap = new Map<Id, Boolean>();
        Map<Id, List<ABHFL_Payment__c>> paymentsMap = new Map<Id, List<ABHFL_Payment__c>>();
		for(ABHFL_Payment__c payment : [SELECT Id, Realization_Status__c, Case__c FROM ABHFL_Payment__c WHERE Case__c IN :caseRecords])
        {
            if(!paymentsMap.containsKey(payment.Case__c)){
                paymentsMap.put(payment.Case__c, new List<ABHFL_Payment__c>());
            }
            paymentsMap.get(payment.Case__c).add(payment);
        }
        for(Case caseRec : caseRecords){
            returnMap.put(caseRec.Id, true);//default true; // All payment records have Realization_Status__c as 'Cleared'
            if(paymentsMap.containsKey(caseRec.Id)){
                // Check if every payment record has Realization_Status__c equal to 'Cleared'
                for (ABHFL_Payment__c payment : paymentsMap.get(caseRec.Id)) {
                    if (payment.Realization_Status__c == null) {
                        returnMap.put(caseRec.Id, false); // If any payment record is not cleared, return false
                        break;
                    }
                }
            }
        }
        paymentsMapStatic = paymentsMap;
        return returnMap; 
    }
    
    //Dhinesh - 2/8 Send Preclosure loan closed email.
	public static void sendLoanClosedEmail(List<Case> caseRecords){
    	//Case queriedCase = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c
        //               FROM Case WHERE Id = :caseRecord.Id];
        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        for(Case caseRec : caseRecords){
            emailTemplateMap.put(caseRec.Id, ABHFL_Constants.PRECLS_LOANCLOSED_EMAIL);
            smsMetadataMap.put(caseRec.Id, ABHFL_Constants.PRECLS_LOANCLOSED_SMS);
            isTransferredMap.put(caseRec.Id, false);
        }

        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecords,emailTemplateMap, 
        smsMetadataMap, isTransferredMap);
    }
    //Dhinesh - 1/29 Backward Movement Email Communication
    public static void backwardMovementEmail(List<Case> caseList, Map<Id, Case> oldCaseMap){
        List<String> validSubTypes = new List<String>{'qbccdd01', 'hfl060','RRSDPRSHFC01'};
        Set<Id> caseDetailIds = new Set<Id>();
        for (Case caseRecord : caseList) {
        	Case originalCase = oldCaseMap.get(caseRecord.Id);
            
            String previousStage = originalCase.Stage__c;	
        	String currentStage = caseRecord.Stage__c;
        	String subType = caseRecord.CCC_External_Id__c;

        	// for payment bounce / not received email and sms
        	if ('CPU Banking'.equals(previousStage) && 'Open'.equals(currentStage) && validSubTypes.contains(subType) && caseRecord.Business_Unit__c == 'ABHFL') {
            	sendEmail(caseRecord);
        	}
            //for Shortfall email/sms - only for Pre Closure (hfl060)
            
            if ('CPU FCL Issuance'.equals(previousStage) && 'Open'.equals(currentStage) && 'hfl060'.equals(subType) && caseRecord.Business_Unit__c == 'ABHFL') {
                 caseDetailIds.add(caseRecord.ABHFL_Case_Detail__c);
            }
            
    	}
        if (!caseDetailIds.isEmpty()) {
        		Map<Id, ABHFL_Case_Detail__c> caseDetailMap = new Map<Id, ABHFL_Case_Detail__c>([SELECT Id, Shortfall_Amount__c FROM ABHFL_Case_Detail__c WHERE Id IN :caseDetailIds]);
        
        		for (Case caseRecord : caseList) {
            		if (caseDetailMap.containsKey(caseRecord.ABHFL_Case_Detail__c)) {
                		ABHFL_Case_Detail__c caseDetail = caseDetailMap.get(caseRecord.ABHFL_Case_Detail__c);
                		if (caseDetail.Shortfall_Amount__c != null) {
                    		ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, ABHFL_Constants.SHORTFALL_TEMPLATE, ABHFL_Constants.SHORTFALL_SMS, false); 
                		}
            		    }
        		}
    	}
    }
    public static void sendEmail(Case caseRecord){
       List<ABHFL_Payment__c> casePayments = [SELECT Id,Realization_Status__c FROM ABHFL_Payment__c WHERE Case__c =: caseRecord.Id];
        for(ABHFL_Payment__c pay : casePayments){
            if(pay.Realization_Status__c == 'Bounce'){
                ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord,ABHFL_Constants.PAYMENT_BOUNCE_TEMPLATE, 
                                                                ABHFL_Constants.PAYMENT_BOUNCE_SMS, False);
            }
            if(pay.Realization_Status__c == 'Not Received'){
                ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord,ABHFL_Constants.PAYMENT_NOTRECEIVED_TEMPLATE, 
                                                                ABHFL_Constants.PAYMENT_NOTRECEIVED_SMS, False);
            }
        }    
    }
    
    //Dhinesh - 1/30 Payment Received email from stage specific.
    public static void sendEmailPaymentReceived(List<Case> caseRecords){
        List<String> validSubTypes = new List<String>{'qbccdd01', 'hfl060','RRSDPRSHFC01'};
        //Case queriedCase = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c
        //               FROM Case WHERE Id = :caseRecord.Id];
        Map<Id, List<ABHFL_Payment__c>> paymentsMap = new Map<Id, List<ABHFL_Payment__c>>();
        if(!paymentsMapStatic.isEmpty()){
            paymentsMap = paymentsMapStatic;
        }else{
            for(ABHFL_Payment__c payment : [SELECT Id, Realization_Status__c, Case__c FROM ABHFL_Payment__c WHERE Case__c IN :caseRecords])
            {
                if(!paymentsMap.containsKey(payment.Case__c)){
                    paymentsMap.put(payment.Case__c, new List<ABHFL_Payment__c>());
                }
                paymentsMap.get(payment.Case__c).add(payment);
            }
        }
        Map<Id, Boolean> paymentRecievedMap = new Map<Id, Boolean>();
        for(Case caseRec : caseRecords){
            if(paymentsMap.containsKey(caseRec.Id)){
                for (ABHFL_Payment__c payment : paymentsMap.get(caseRec.Id)) {
                    if(payment.Realization_Status__c == 'Cleared'){
                        paymentRecievedMap.put(caseRec.Id, true);
                        break;
                    }
                }
            }
        }

        List<Case> eligibleCases = new List<Case>();
        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        for(Case caseRec : caseRecords){
            if(paymentRecievedMap.containsKey(caseRec.Id) && paymentRecievedMap.get(caseRec.Id) && validSubTypes.contains(caseRec.CCC_External_Id__c)){
                eligibleCases.add(caseRec);
                emailTemplateMap.put(caseRec.Id, ABHFL_Constants.PAYMENT_RECEIVED_TEMPLATE);
                smsMetadataMap.put(caseRec.Id, ABHFL_Constants.PAYMENT_RECEIVED_SMS);
                isTransferredMap.put(caseRec.Id, false);
            }
        }

        if(!eligibleCases.isEmpty()){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(eligibleCases,emailTemplateMap, 
            smsMetadataMap, isTransferredMap);
        }
    }
    public static void executeSpecificIntegrations(List<Case> newCases, List<Case> oldCases){
        if((!oldCases.isEmpty() && String.isEmpty(oldCases[0].Sub_Type_Text__c)  && oldCases[0].Sub_Type_Text__c != newCases[0].Sub_Type_Text__c) || oldCases.isEmpty()){
            Set<String> c3ExternalIds = new Set<String>();
            Map<String, List<ASF_Integration__c>> uiCardIntegrationMap = new Map<String, List<ASF_Integration__c>>();

            for(case cs : newCases){
                c3ExternalIds.add(cs.CCC_External_Id__c);
            }
            // List<String> asfIntegrationNames = new List<String>{'ABHFL_ASFIntg_REKYC', 'ABHFL_ASFIntg_BitlyUrl'};
            List<ASF_Integration__c> specificIntegrations = [SELECT ID, Auto_Run_on_Load__c ,C3ExternalId__c, Display_Name__c ,Display_Order__c ,STP_API_Identifier__c,
            External_Id__c,Mandatory_At_Stage_Movement__c ,Processing_Class__c ,STP_Processing_Class__c, Type__c,
            UI_Component__c ,Visibility_Class__c ,When_to_Appear__c, Query_Fields__c, Priority__c  FROM ASF_Integration__c WHERE C3ExternalId__c in : c3ExternalIds AND Type__c = 'UI Card'];

            for(ASF_Integration__c asfCaseInteg : specificIntegrations){
                if(!uiCardIntegrationMap.containsKey(asfCaseInteg.C3ExternalId__c)){
                    uiCardIntegrationMap.put(asfCaseInteg.C3ExternalId__c, new List<ASF_Integration__c>());
                }
                uiCardIntegrationMap.get(asfCaseInteg.C3ExternalId__c).add(asfCaseInteg);
            }

            List<Case> applicableCases = new List<Case>();
            Map<Id, List<ASF_Integration__c>> integMap = new Map<Id, List<ASF_Integration__c>>();
            for(Case cs : newCases){
                if(cs.Business_Unit__c == 'ABHFL' && cs.Technical_Source__c != 'API' && uiCardIntegrationMap.containsKey(cs.CCC_External_Id__c)){
                    applicableCases.add(cs);
                    integMap.put(cs.Id, uiCardIntegrationMap.get(cs.CCC_External_Id__c));
                }
            }
            if(!applicableCases.isEmpty()){
                ASF_CaseFrameworkHelper.runIntegrations(applicableCases, integMap);
            }
        }
    }
    //Dhinesh - to Send Tracking Links
    public static void sendTrackingLink(List<Case> caseRecords){
        List<String> validSubTypes = new List<String>{'qbccdd01', 'hfl060','RRSDPRSHFC01'};
        //Id caseId = caseRec.Id; 
    	//Case caseRecord = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c,Short_URL__c
        //               FROM Case WHERE Id = :caseId];

        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        List<Case> eligibleCases = new List<Case>();
        for(Case caseRecord : caseRecords){
            if(caseRecord.Short_URL__c != NULL && validSubTypes.contains(caseRecord.CCC_External_Id__c)){
                smsMetadataMap.put(caseRecord.Id, ABHFL_Constants.TRACKING_LINK_SMS);
                isTransferredMap.put(caseRecord.Id, false);
                eligibleCases.add(caseRecord);
                
            }
        }
        if(!eligibleCases.isEmpty()){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(eligibleCases, 
                                                                    NULL, 
                                                                    smsMetadataMap, 
                                                                    isTransferredMap);
        }
    }
    //Dhinesh - to send attachments with mail for GST Invoice Required, DSRA/Lien Document and Escrow Statement
   public static void sendMailWithAttachments(List<Case> caseRecs) {
    	//Id caseId = caseRec.Id; 
	    //Case caseRecord = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c, Short_URL__c FROM Case WHERE Id = :caseId];
        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        List<Case> eligibleCases = new List<Case>();
        for(Case caseRecord : caseRecs){
            if (caseRecord.CCC_External_Id__c == ABHFL_Constants.GST_INVOICE_ID) {
                emailTemplateMap.put(caseRecord.ID, ABHFL_Constants.GST_INVOICE_EMAIL);
                smsMetadataMap.put(caseRecord.Id, ABHFL_Constants.GST_INVOICE_SMS);
                isTransferredMap.put(caseRecord.Id, true);
                eligibleCases.add(caseRecord);
            } else if (caseRecord.CCC_External_Id__c == ABHFL_Constants.DSRA_LIEN_ID) {
                emailTemplateMap.put(caseRecord.ID, ABHFL_Constants.DSRA_LIEN_EMAIL);
                smsMetadataMap.put(caseRecord.Id, ABHFL_Constants.DSRA_LIEN_SMS);
                isTransferredMap.put(caseRecord.Id, true);
                eligibleCases.add(caseRecord);
            } else if (caseRecord.CCC_External_Id__c == ABHFL_Constants.ESCROW_STATEMENT_ID) {
                emailTemplateMap.put(caseRecord.ID, ABHFL_Constants.ESCROW_STATEMENT_EMAIL);
                smsMetadataMap.put(caseRecord.Id, ABHFL_Constants.ESCROW_STATEMENT_SMS);
                isTransferredMap.put(caseRecord.Id, true);
                eligibleCases.add(caseRecord);
            } else if (caseRecord.CCC_External_Id__c == ABHFL_Constants.NOC_REQUIRED_ID){
                emailTemplateMap.put(caseRecord.ID, ABHFL_Constants.ESCROW_STATEMENT_EMAIL);
                smsMetadataMap.put(caseRecord.Id, ABHFL_Constants.ESCROW_STATEMENT_SMS);
                isTransferredMap.put(caseRecord.Id, true);
                eligibleCases.add(caseRecord);
            }
        }

        if(!eligibleCases.isEmpty()){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(eligibleCases, emailTemplateMap, smsMetadataMap, isTransferredMap);
        }
    	
	}
    //Dhinesh - to store multi lan in a field and send payment confirmation mail
    public static void storeMultipleLANs(List<Case> caseRecs){
        //Case caseRecord = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c,Short_URL__c
        //               FROM Case WHERE Id = :caseRec.Id];

        Map<Id, List<ABHFL_Asset_Detail__c>> caseIdToRelatedAssets = new Map<Id, List<ABHFL_Asset_Detail__c>>();
        for(ABHFL_Asset_Detail__c asset : [SELECT Id, Case__c, Asset__r.LAN__c,Revised_ROI__c FROM ABHFL_Asset_Detail__c WHERE Case__c IN :caseRecs]){
            if(!caseIdToRelatedAssets.containsKey(asset.Case__c)){
                caseIdToRelatedAssets.put(asset.Case__c, new List<ABHFL_Asset_Detail__c>());
            }
            caseIdToRelatedAssets.get(asset.Case__c).add(asset);
        }
        
        //These fields will be part of Query Field on Stage config, and will come via case record.
        //ABHFL_Case_Detail__c caseDetail = [SELECT Id,Masked_Full_LANs__c,Payment_Status__c FROM ABHFL_Case_Detail__c WHERE Id =:caseRec.ABHFL_Case_Detail__c LIMIT 1];

        Map<Id, ABHFL_Case_Detail__c> caseIdToCaseExtnMap = new Map<Id, ABHFL_Case_Detail__c>();
        for(Case caseRec : caseRecs){
            if(caseIdToRelatedAssets.containsKey(caseRec.Id)){
                String result = '';
                List<ABHFL_Asset_Detail__c> relatedAssets = caseIdToRelatedAssets.get(caseRec.Id);
                for (Integer i = 0; i < relatedAssets.size(); i++) {
                    ABHFL_Asset_Detail__c assetDetail = relatedAssets[i];
                    String maskedLan = 'xxxxxx' + assetDetail.Asset__r.LAN__c.substring(Math.max(0, assetDetail.Asset__r.LAN__c.length() - 4));
                    if (i == relatedAssets.size() - 1) {
                        // Last iteration, use 'and'
                        result += ' and ' + maskedLan;
                    } else {
                    // Other iterations, use comma if not the first iteration
                        if (i > 0) {
                            result += ', ';
                        }
                        result += maskedLan;
                    }
                }
                ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
                caseDetail.Id = caseRec.ABHFL_Case_Detail__c;
                caseDetail.Masked_Full_LANs__c = result;
                caseIdToCaseExtnMap.put(caseRec.Id, caseDetail);
            }
        }
        update caseIdToCaseExtnMap.values();

        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        List<Case> eligibleCases = new List<Case>();
        for(Case caseRec : caseRecs){
            if(caseIdToCaseExtnMap.containsKey(caseRec.Id)){
                ABHFL_Case_Detail__c caseDetail = caseIdToCaseExtnMap.get(caseRec.Id);
                if(caseDetail.Masked_Full_LANs__c != NULL && caseRec.ABHFL_Case_Detail__r.Payment_Status__c == 'Payment Received'){
                    eligibleCases.add(caseRec);
                    emailTemplateMap.put(caseRec.Id, ABHFL_Constants.MULTIPLELAN_PAYMENT_RECEIVED_EMAIL);
                    smsMetadataMap.put(caseRec.Id, ABHFL_Constants.MULTIPLELAN_PAYMENT_RECEIVED_SMS);
                    isTransferredMap.put(caseRec.Id, false);
                }
            }
        }
        if(!eligibleCases.isEmpty()){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(eligibleCases, emailTemplateMap, smsMetadataMap, isTransferredMap);
        }
     
    }
    public static void sendPrclsStatementclosure(List<Case> caseRecs){
        //Case caseRecord = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c,ABHFL_Case_Detail__c
        //               FROM Case WHERE Id = :caseRec.Id];

        Map<Id, List<ABHFL_Asset_Detail__c>> caseIdToRelatedAssets = new Map<Id, List<ABHFL_Asset_Detail__c>>();
        for(ABHFL_Asset_Detail__c asset : [SELECT Id, Case__c, Asset__r.LAN__c,Revised_ROI__c FROM ABHFL_Asset_Detail__c WHERE Case__c IN :caseRecs]){
            if(!caseIdToRelatedAssets.containsKey(asset.Case__c)){
                caseIdToRelatedAssets.put(asset.Case__c, new List<ABHFL_Asset_Detail__c>());
            }
            caseIdToRelatedAssets.get(asset.Case__c).add(asset);
        }

        Map<Id, ABHFL_Case_Detail__c> caseIdToCaseExtnMap = new Map<Id, ABHFL_Case_Detail__c>();
        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        for(Case caseRec : caseRecs){
            emailTemplateMap.put(caseRec.Id, ABHFL_Constants.MULTIPLELAN_PRCLS_STATEMENT_CLOSUREEMAIL);
            smsMetadataMap.put(caseRec.Id, ABHFL_Constants.MULTIPLELAN_PRCLS_STATEMENT_CLOSURESMS);
            isTransferredMap.put(caseRec.Id, true);
            if(caseIdToRelatedAssets.containsKey(caseRec.Id)){
                String result = '';
                List<ABHFL_Asset_Detail__c> relatedAssets = caseIdToRelatedAssets.get(caseRec.Id);
                for (Integer i = 0; i < relatedAssets.size(); i++) {
                    ABHFL_Asset_Detail__c assetDetail = relatedAssets[i];
                    String maskedLan = 'xxxxxx' + assetDetail.Asset__r.LAN__c.substring(Math.max(0, assetDetail.Asset__r.LAN__c.length() - 4));
                    if (i == relatedAssets.size() - 1) {
                        // Last iteration, use 'and'
                        result += ' and ' + maskedLan;
                    } else {
                    // Other iterations, use comma if not the first iteration
                        if (i > 0) {
                            result += ', ';
                        }
                        result += maskedLan;
                    }
                }
                ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
                caseDetail.Id = caseRec.ABHFL_Case_Detail__c;
                caseDetail.Masked_Full_LANs__c = result;
                caseIdToCaseExtnMap.put(caseRec.Id, caseDetail);
            }
        }
        update caseIdToCaseExtnMap.values();
        
        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecs, emailTemplateMap, smsMetadataMap, isTransferredMap);
    }
    public void prePopulateFields(List<Case> newCaseList) {

        prePopulateABHFL_Case_Detail_Fields(newCaseList);
    }

    public void prePopulateABHFL_Case_Detail_Fields(List<Case> newCaseList) {
        
        List<String> cccExternalIdList = new List<String>();
        Map<String,String> mapOfCaseDetIdToCcccExtId = new Map<String,String>();
        Map<String, Doc_Charge__mdt> mapOf_CCCExternalId_To_DocChargeRec = new Map<String, Doc_Charge__mdt>();

        for(Case csRec : newCaseList) {
            
            String bussUnit = csRec.Business_Unit__c;
            String cccExtId = csRec.CCC_External_Id__c;
            String abflCasDetId = csRec.ABHFL_Case_Detail__c;

            if(bussUnit == 'ABHFL') {
                mapOfCaseDetIdToCcccExtId.put(abflCasDetId, cccExtId);
                cccExternalIdList.add(cccExtId);
            } 
        }

        if(cccExternalIdList.size() == 0) {
            return;
        }

        List<Doc_Charge__mdt> docChargeMdtLst = [SELECT id, Amount__c, CCC_External_Id__c
                                                FROM Doc_Charge__mdt
                                                WHERE CCC_External_Id__c =:cccExternalIdList];

        for(Doc_Charge__mdt docChrge : docChargeMdtLst) {
            mapOf_CCCExternalId_To_DocChargeRec.put(docChrge.CCC_External_Id__c, docChrge);
        }

        List<ABHFL_Case_Detail__c> abhfl_CaseDetail_List = [SELECT id, Payable_Charges__c
                                                            FROM ABHFL_Case_Detail__c
                                                            WHERE id in :mapOfCaseDetIdToCcccExtId.keyset()];

        for(ABHFL_Case_Detail__c csDet : abhfl_CaseDetail_List) {

            String csDetId = csDet.Id;
            String cccExternal = mapOfCaseDetIdToCcccExtId.get(csDetId);
            Decimal roiSwitchFee =  mapOf_CCCExternalId_To_DocChargeRec.containsKey(cccExternal) ? mapOf_CCCExternalId_To_DocChargeRec.get(cccExternal).Amount__c : 0;

            csDet.Payable_Charges__c = roiSwitchFee;
        }

        if(abhfl_CaseDetail_List.size() > 0) {
            update abhfl_CaseDetail_List;    
        }
    }

    public void  ICAndPICEvaluationOnApiCall(List<Case> newCaseLst) {

        ABHFL_ICAndPIC_Integration abhflICAndPICIntegrationClss = new ABHFL_ICAndPIC_Integration();
        List<String> cccExternalIdOfCTSTList = new List<String>{'hfl037', 'hfl078'};
        List<String> caseIdList = new List<String>();
        List<Case> evaluationCaseList = new List<Case>();
        List<Case> frameworkCaseList = new List<Case>();
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;

        Map<ID,List<Case>> mRecordTypeVsCases1 = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newCaseLst);
        if(mRecordTypeVsCases1.containsKey(frameworkRTId)){
            frameworkCaseList = mRecordTypeVsCases1.get(frameworkRTId);
        }

        for(Case csRecord : frameworkCaseList) {
            String cccExternalIdCase = csRecord.CCC_External_Id__c;
            String bussUnitOfCase = csRecord.Business_Unit__c;
            String caseTechnicalSource = csRecord.Technical_Source__c;

            if(cccExternalIdOfCTSTList.contains(cccExternalIdCase) && bussUnitOfCase == 'ABHFL' && caseTechnicalSource == 'API') {
                evaluationCaseList.add(csRecord);
            }
        }

        if(evaluationCaseList.size() > 0) {
            abhflICAndPICIntegrationClss.evaluate(evaluationCaseList);
        }
    }

    public void callLitmusApi(List<Case> newCaseList, Map<Id, Case> oldCases) {
        
        ABHFL_LitmusApi litmusApiObj = new ABHFL_LitmusApi();
        Case newCaseRec = newCaseList[0];
        String businessUnit = newCaseRec.Business_Unit__c;
        
        if(businessUnit == 'ABHFL') {
            ASF_IntegrationsController.IntegrationWrapper result = litmusApiObj.evaluate(newCaseRec);
            if(result.status == 'Success') {
                ASF_IntegrationsController.IntegrationWrapper resultOfRun = litmusApiObj.run(new ASF_Integration__c(), newCaseRec);
            }
        }
    }

    public void populateFieldsInAfterContext(List<Case> newCaseList) {
        populateFieldsOfABHFL_CaseDetail(newCaseList);
    }

    public void populateFieldsOfABHFL_CaseDetail(List<Case> newCaseList) {
        
        List<String> caseDetIdList = new List<String>();
        List<ABHFL_Case_Detail__c> caseDetListToUpdate = new List<ABHFL_Case_Detail__c>();

        for(Case cs : newCaseList) {

            String technicalSource = cs.Technical_Source__c;
            String businessUnt = cs.Business_Unit__c;
            String csDetId = cs.ABHFL_Case_Detail__c;

            if(technicalSource == 'API' && businessUnt == 'ABHFL') {
                if(String.isNotBlank(csDetId)) {
                    caseDetIdList.add(csDetId);
                }
            }
        }

        List<ABHFL_Case_Detail__c> csDetList = [SELECT From_Year__c, To_Year__c, Financial_Year__c
                                                FROM ABHFL_Case_Detail__c
                                                WHERE id in :caseDetIdList];
        
        for(ABHFL_Case_Detail__c csDet : csDetList) {

            String fromYr = csDet.From_Year__c;
            String toYr   = csDet.To_Year__c;

            if(String.isNotBlank(fromYr) && String.isNotBlank(toYr)) {
                String lastTwoDigitOfToYr = toYr.right(2);
                csDet.Financial_Year__c = fromYr + '-' + lastTwoDigitOfToYr;
                caseDetListToUpdate.add(csDet);
            }
        }

        if(caseDetListToUpdate.size() > 0) {
            update caseDetListToUpdate;
        }
    }

    public static Case createCases(String clientCode, String lan, String ccc, String source, String techSource, Id parentCaseId, id recordTypeId ) {
        Case caseRecord = new Case();
        caseRecord.Business_Unit__c = 'ABHFL';
        caseRecord.Client_Code_Text__c = clientCode;
        caseRecord.Source__c = source;
        caseRecord.Technical_Source__c = 'LWC';
        caseRecord.CCC_External_Id__c = ccc;
        caseRecord.LAN__C = lan;
        caseRecord.RecordTypeId = recordTypeId;
        caseRecord.parentId = parentCaseId;
        return caseRecord;
    }
    
    public static void insertCases(List<Case> caseList) {
        if(!caseList.isempty()){
             insert caseList;
        }
    }

    public static void sendCommunicationPayableCharges(List<Case> caseRecords){
        //Case queriedCase = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c, ABHFL_Case_Detail__c
        //               FROM Case WHERE Id = :caseRecord.Id];
        //ABHFL_Case_Detail__c caseDetail = [SELECT Id,Payable_Charges__c FROM ABHFL_Case_Detail__c WHERE Id =:queriedCase.ABHFL_Case_Detail__c LIMIT 1];
        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        List<Case> typeOneCases = new List<Case>();
        List<Case> typeTwoCases = new List<Case>();
        for(Case caseRec : caseRecords){
            if(Integer.valueOf(caseRec.ABHFL_Case_Detail__r.Payable_Charges__c) > 0){
                System.debug('greater then 0');
                typeOneCases.add(caseRec);
                emailTemplateMap.put(caseRec.Id, ABHFL_Constants.ROI_OFFERSHARED_WITH_PAYABLE_CHARGES_EMAIL);
                smsMetadataMap.put(caseRec.Id, ABHFL_Constants.ROI_OFFERSHARED_WITH_PAYABLE_CHARGES_SMS);
                isTransferredMap.put(caseRec.Id, false);
            }else{
                System.debug(' equals zero');
                typeTwoCases.add(caseRec);
                emailTemplateMap.put(caseRec.Id, ABHFL_Constants.ROI_OFFERSHARED_WITHOUT_PAYABLE_CHARGES_EMAIL);
                smsMetadataMap.put(caseRec.Id, ABHFL_Constants.ROI_OFFERSHARED_WITHOUT_PAYABLE_CHARGES_SMS);
                isTransferredMap.put(caseRec.Id, false);
            }
        }
        if(!typeOneCases.isEmpty()){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(typeOneCases, emailTemplateMap, smsMetadataMap, isTransferredMap);
        }
        if(!typeTwoCases.isEmpty()){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(typeTwoCases, emailTemplateMap, smsMetadataMap, isTransferredMap);
        }
    }
    
    public static Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper> checkAssetDetailStatus(Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> caseIdCaseMovementWrapperMap){
        List<String> validCTSTs= new List<String>{'hfl069','RLOAPRONHFC','RRESRONTHFC','RRESROONHFC','REFCL001','RRSDPRSHFC01'};
        List<String> validCTSTsEditFields= new List<String>{'hfl069','RRESRONTHFC','RRESROONHFC'};
        List<String> validCTSTsCPUPP = new List<String>{'hfl069','RRESRONTHFC'};
        List<String> validCTSTsROI= new List<String>{'hfl069','RRESRONTHFC','RRESROONHFC'};
        List<String> validStagesForRevisedEMITenure= new List<String>{'Resolved','Pending Amortization'};
        Map<Id,Case> caseRecordsPaymentDetailsMap = new Map<Id,Case>([Select id,CCC_External_Id__c,Stage__c,Previous_Stage__c,Technical_Source__c,
                                                                     (Select id,Revised_ROI__c,Impact__c,Cycle_Date__c,Revised_EMI_Tenure__c
                                                                      from Asset_Details__r)
                                                                      from Case where id in: caseIdCaseMovementWrapperMap.keySet()]);
        for(Id recId : caseIdCaseMovementWrapperMap.keySet()){
            if(caseRecordsPaymentDetailsMap.containsKey(recId)){
                Case caseRec = caseRecordsPaymentDetailsMap.get(recId);
                if(validCTSTs.contains(caseRec.CCC_External_Id__c) && caseRec.Technical_Source__c == 'LWC'){
                    ASF_CaseMovementHelper.CaseStageValidationWrapper caseStgValidationWrapper = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
                    caseStgValidationWrapper.status = ABHFL_Constants.ERROR;
                    caseStgValidationWrapper.isCaseUpdated = false;
                    
                    if(caseRec.Asset_Details__r.size() == 0){
                        caseStgValidationWrapper.errorMessage = 'Please select atleast one LAN';
                        caseIdCaseMovementWrapperMap.put(caseRec.Id,caseStgValidationWrapper);
                    } else if(caseRec.Asset_Details__r.size() >= 0 && validCTSTsEditFields.contains(caseRec.CCC_External_Id__c)){
                        Boolean assetRecordComplete = true;
                        for(integer i = 0; i < caseRec.Asset_Details__r.size(); i++){
                            ABHFL_Asset_Detail__c assetDetail = caseRec.Asset_Details__r[i];
                            if(validCTSTsROI.contains(caseRec.CCC_External_Id__c)){
                                if(assetDetail.Revised_ROI__c == null || assetDetail.Revised_ROI__c == 0 || 
                                   String.isBlank(assetDetail.Impact__c) || String.isBlank(assetDetail.Cycle_Date__c)){
                                    assetRecordComplete = false;
                                    break;
                                }
                            }

                            /*if(validCTSTsCPUPP.contains(caseRec.CCC_External_Id__c) && validStagesForRevisedEMITenure.contains(caseRec.Stage__c)){
                                if(assetDetail.Revised_EMI_Tenure__c == null || assetDetail.Revised_EMI_Tenure__c == 0){
                                    assetRecordComplete = false;
                                    break;
                                }
                            }*/
                        }
                        if(!assetRecordComplete){
                            caseStgValidationWrapper.errorMessage = 'Please fill all the information on the LAN Record';
                            caseIdCaseMovementWrapperMap.put(caseRec.Id,caseStgValidationWrapper);
                        }
                    }
                }
            }
        }

        return caseIdCaseMovementWrapperMap;
    }
    
    public static Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper> checkAssetDetailFileUploadStatus(Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> caseIdCaseMovementWrapperMap){
        List<String> validCTSTs = new List<String>{'REFCL001','RLOAPRONHFC','RRSDPRSHFC01'};
        Map<Id,Case> caseRecordsPaymentDetailsMap = new Map<Id,Case>([Select id,CCC_External_Id__c,Stage__c,Previous_Stage__c,Technical_Source__c,
                                                                     (Select id,Revised_ROI__c,Impact__c,Cycle_Date__c,Revised_EMI_Tenure__c
                                                                      from Asset_Details__r)
                                                                      from Case where id in: caseIdCaseMovementWrapperMap.keySet()]);

        List<Case> validCases = new List<Case>();
        Set<Id> assetDetailIds = new Set<Id>();
        for(Case caseRecord : caseRecordsPaymentDetailsMap.values()){
            if(validCTSTs.contains(caseRecord.CCC_External_Id__c) && caseRecord.Stage__c == 'Resolved'){
                validCases.add(caseRecord);
                for(ABHFL_Asset_Detail__c assetDetail : caseRecord.Asset_Details__r){
                    assetDetailIds.add(assetDetail.Id);
                }
            }
        }          

        Map<Id,Id> assetDetailIdContentIdMap = new Map<Id,Id>();
        if(assetDetailIds.size() > 0){
            List<ContentDocumentLink> contentDocLinkList = [Select id,LinkedEntityId,ContentDocumentId from ContentDocumentLink where LinkedEntityId in: assetDetailIds];

            for(ContentDocumentLink docLink : contentDocLinkList){
                assetDetailIdContentIdMap.put(docLink.LinkedEntityId,docLink.ContentDocumentId);
            }
        }

        for(Case caseRec : validCases){
            Boolean attachmentPresent = true;
            for(ABHFL_Asset_Detail__c assetDetail : caseRec.Asset_Details__r){
                if(!assetDetailIdContentIdMap.containsKey(assetDetail.Id)){
                    attachmentPresent = false;
                    break;
                }
            }
            if(!attachmentPresent){
                ASF_CaseMovementHelper.CaseStageValidationWrapper caseStgValidationWrapper = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
                caseStgValidationWrapper.status = ABHFL_Constants.ERROR;
                caseStgValidationWrapper.isCaseUpdated = false;
                caseStgValidationWrapper.errorMessage = 'Please upload a document for all LANs';
                caseIdCaseMovementWrapperMap.put(caseRec.Id,caseStgValidationWrapper);
            }
        }

        return caseIdCaseMovementWrapperMap;
    }

}
