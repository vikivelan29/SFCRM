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
    	List<String> emailFinancialSubTypes = new List<String>{'hfcrepaprod','RREPEMIONHFC','ROVEOVSSHFC','hfl029'};
    	List<String> emailNonFinancialSubTypes = new List<String>{'AC123470','HFCRARGI'}; 
        List<String> customerServiceSubTypes = new List<String>{'hfl060'};
    	Group emailNonFinancialQueue = [SELECT Id,Name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Email_Non_Financial_Team' WITH SECURITY_ENFORCED LIMIT 1];
    	Group emailFinancialQueue = [SELECT Id,Name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Email_Financial_Team' WITH SECURITY_ENFORCED LIMIT 1];
        Group customerServiceQueue = [SELECT Id,Name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' WITH SECURITY_ENFORCED LIMIT 1];
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
        if (customerServiceSubTypes.contains(subType)) {
        	if (caseRec.Source__c == ABHFL_Constants.BRANCH) {
            updatedCase.OwnerId = caseRec.CreatedById;
            ownerName = caseRec.CreatedBy.Name;
        	} else {
            updatedCase.OwnerId = customerServiceQueue.Id;
            ownerName = customerServiceQueue.Name;
        		}
    	}

    	if (subType == 'RRSDPRSHFC01') {
        	updatedCase.OwnerId = emailFinancialQueue.Id;
            ownerName = emailFinancialQueue.Name;
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
        if(!eligibleCases.isEmpty()){
            Map<Id, Branch_Master__c> caseIdToBranchMap = new Map<Id, Branch_Master__c>();
            for(Branch_Master__c branch : [SELECT Id,Branch_Queue_Id__c,Address__c, UniqueKey__c FROM Branch_Master__c WHERE UniqueKey__c IN: uniqueKeyToCaseId.keySet()])
            {
                caseIdToBranchMap.put(uniqueKeyToCaseId.get(branch.UniqueKey__c), branch);
            }
            for(Case caseRec : eligibleCases){
                if(caseIdToBranchMap.get(caseRec.Id).Branch_Queue_Id__c != null){
                    Case blankCase = new Case(Id = caseRec.Id);
                    blankCase.OwnerId = caseIdToBranchMap.get(caseRec.Id).Branch_Queue_Id__c;
                    updatedCasesMap.put(blankCase.Id, blankCase);
                }
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
                ABHFL_Case_Detail__c caseDetail =  [SELECT Id,Shortfall_Amount__c FROM ABHFL_Case_Detail__c WHERE Id =: caseRecord.ABHFL_Case_Detail__c];
                if(caseDetail.Shortfall_Amount__c !=  Null){
                   ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord,ABHFL_Constants.SHORTFALL_TEMPLATE, 
                                                                ABHFL_Constants.SHORTFALL_SMS, False); 
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
            UI_Component__c ,Visibility_Class__c ,When_to_Appear__c, Query_Fields__c  FROM ASF_Integration__c WHERE C3ExternalId__c in : c3ExternalIds AND Type__c = 'UI Card'];

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
        caseRecord.Technical_Source__c = techSource;
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
        Map<Id,Case> caseRecordsPaymentDetailsMap = new Map<Id,Case>([Select id,CCC_External_Id__c,Stage__c,Previous_Stage__c,
                                                                     (Select id,Revised_ROI__c,Impact__c,Cycle_Date__c,Revised_EMI_Tenure__c
                                                                      from Asset_Details__r)
                                                                      from Case where id in: caseIdCaseMovementWrapperMap.keySet()]);
        for(Id recId : caseIdCaseMovementWrapperMap.keySet()){
            if(caseRecordsPaymentDetailsMap.containsKey(recId)){
                Case caseRec = caseRecordsPaymentDetailsMap.get(recId);
                if(validCTSTs.contains(caseRec.CCC_External_Id__c)){
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

                            if(validCTSTsCPUPP.contains(caseRec.CCC_External_Id__c) && validStagesForRevisedEMITenure.contains(caseRec.Stage__c)){
                                if(String.isBlank(assetDetail.Revised_EMI_Tenure__c)){
                                    assetRecordComplete = false;
                                    break;
                                }
                            }
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
    
}