/*********************************************************
*@Class        :  ABHFL_CTSTHelper
*@Author       :  Dhinesh Kumar T
*@Created Date :  12/25/2023
*@Last Modified:  01/11/2024
*@description  :  Class for ABHFL Specific Methods. 
*********************************************************/
public without sharing class ABHFL_CTSTHelper {
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
    	List<String> emailFinancialSubTypes = new List<String>{'hfcrepaprod','RREPEMIONHFC','ROVEOVSSHFC','hfl029'};
    	List<String> emailNonFinancialSubTypes = new List<String>{'AC123470','HFCRARGI'}; 
        List<String> customerServiceSubTypes = new List<String>{'hfl060'};
    	Group emailNonFinancialQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Email_Non_Financial_Team' WITH SECURITY_ENFORCED LIMIT 1];
    	Group emailFinancialQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Email_Financial_Team' WITH SECURITY_ENFORCED LIMIT 1];
        Group customerServiceQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' WITH SECURITY_ENFORCED LIMIT 1];
		// Create a new instance to avoid trigger recursion
   	 	Case updatedCase = new Case(Id = caseRecord.Id);
		// assign the case to a queue 
    	if (emailNonFinancialSubTypes.contains(subType)) {
        	if (caseRecord.Source__c == ABHFL_Constants.BRANCH) {
            updatedCase.OwnerId = caseRecord.CreatedById;
        	} else {
            updatedCase.OwnerId = emailNonFinancialQueue.Id;
        	}
    	}

    	if (emailFinancialSubTypes.contains(subType)) {
        	if (caseRecord.Source__c == ABHFL_Constants.BRANCH) {
            updatedCase.OwnerId = caseRecord.CreatedById;
        	} else {
            updatedCase.OwnerId = emailFinancialQueue.Id;
        		}
    	}
        if (customerServiceSubTypes.contains(subType)) {
        	if (caseRecord.Source__c == ABHFL_Constants.BRANCH) {
            updatedCase.OwnerId = caseRecord.CreatedById;
        	} else {
            updatedCase.OwnerId = customerServiceQueue.Id;
        		}
    	}

    	if (subType == 'RRSDPRSHFC01') {
        	updatedCase.OwnerId = emailNonFinancialQueue.Id;
    	}
        List<ASF_Case_SLA_History__c> slaHistory = [SELECT Id, Current_Owner_Id__c FROM ASF_Case_SLA_History__c WHERE Case__c = :caseRecord.Id AND Stage_End_Date__c = NULL Order By CreatedDate Desc LIMIT 1];

    	if (slaHistory.size() > 0) {
        	delete slaHistory;
    	}
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
    	update new List<Case>{ updatedCase };
	}
    //Dhinesh
    public static Case assignCaseToBranch(Case caseRecord) {
        Case caseRec = [SELECT Id, OwnerId,AssetId,Source__c FROM Case WHERE Id = :caseRecord.Id WITH SECURITY_ENFORCED];
		Asset relatedAsset = [SELECT Id, Branch__r.Branch_Queue_Id__c FROM Asset WHERE Id =: caseRec.AssetId];
        if (relatedAsset.Branch__r.Branch_Queue_Id__c != null && caseRec.Source__c != 'Branch') {
            caseRec.OwnerId = relatedAsset.Branch__r.Branch_Queue_Id__c;
        }

        return caseRec;
    }
    //Dhinesh
    public static Case assignCaseToPreferredBranch(Case caseRecord) {
        Case caseRec = [SELECT Id, OwnerId,ABHFL_Case_Detail__c FROM Case WHERE Id = :caseRecord.Id WITH SECURITY_ENFORCED];
        ABHFL_Case_Detail__c caseDetail = [SELECT Id,Preferred_Branch__c FROM ABHFL_Case_Detail__c WHERE Id =:caseRec.ABHFL_Case_Detail__c LIMIT 1];
		Branch_Master__c prefBranch = [SELECT Id,Branch_Queue_Id__c,Address__c FROM Branch_Master__c WHERE SAP_Code__c =: caseDetail.Preferred_Branch__c LIMIT 1];
        if (prefBranch.Branch_Queue_Id__c != null) {
            caseRec.OwnerId = prefBranch.Branch_Queue_Id__c;
        }
        caseDetail.Address__c = prefBranch.Address__c;
        update caseDetail;
        return caseRec;
    }
    //Dhinesh - updateComplaintType
    @AuraEnabled
    public static void updateCaseExtension(String caseextensionId, String complainttype){
        ABHFL_Case_Detail__c caseDetail = [SELECT Id,Complaint_Type__c FROM ABHFL_Case_Detail__c WHERE Id =:caseextensionId LIMIT 1];
        caseDetail.Complaint_Type__c = complainttype;
        update caseDetail;
    }
    
    //Dhinesh - Used for assigning case to AOM/ROM
    public static Case assignCaseToAOMROM(Case caseRecord){
        Case caseRec = [SELECT Id, OwnerId,ABHFL_Case_Detail__c FROM Case WHERE Id = :caseRecord.Id WITH SECURITY_ENFORCED];
        ABHFL_Case_Detail__c caseDetail = [SELECT Id,Preferred_Branch__c FROM ABHFL_Case_Detail__c WHERE Id =:caseRec.ABHFL_Case_Detail__c LIMIT 1];
        Branch_Master__c prefBranch = [SELECT Id,Branch_Queue_Id__c,ROM_AOM__c FROM Branch_Master__c WHERE SAP_Code__c =: caseDetail.Preferred_Branch__c LIMIT 1];
        if (prefBranch.ROM_AOM__c != null) {
            caseRec.OwnerId = prefBranch.ROM_AOM__c;
        }
        return caseRec;
    }
    
    //Dhinesh
    public static Boolean validatePayments(Case caseRecord) {
        Case queriedCase = [SELECT Id FROM Case WHERE Id = :caseRecord.Id LIMIT 1];
		List<ABHFL_Payment__c> payments = [SELECT Id, Realization_Status__c FROM ABHFL_Payment__c WHERE Case__c = :queriedCase.Id];
		// Check if every payment record has Realization_Status__c equal to 'Cleared'
        for (ABHFL_Payment__c payment : payments) {
            if (payment.Realization_Status__c != 'Cleared') {
                return false; // If any payment record is not cleared, return false
            }
        }

        return true; // All payment records have Realization_Status__c as 'Cleared'
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
    public static void sendEmailPaymentReceived(Case caseRecord){
        List<String> validSubTypes = new List<String>{'qbccdd01', 'hfl060','RRSDPRSHFC01'};
        Case queriedCase = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c
                       FROM Case WHERE Id = :caseRecord.Id];
        Boolean paymentRecieved = false;
    	List<ABHFL_Payment__c> casePayments = [SELECT Id,Realization_Status__c FROM ABHFL_Payment__c WHERE Case__c =: caseRecord.Id];
    	for(ABHFL_Payment__c pay : casePayments){
            if(pay.Realization_Status__c == 'Cleared'){
                paymentRecieved = true;
            }
        }
        if(paymentRecieved && validSubTypes.contains(queriedCase.CCC_External_Id__c)){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(queriedCase,ABHFL_Constants.PAYMENT_RECEIVED_TEMPLATE, 
                                                                ABHFL_Constants.PAYMENT_RECEIVED_SMS, False);
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
            UI_Component__c ,Visibility_Class__c ,When_to_Appear__c  FROM ASF_Integration__c WHERE C3ExternalId__c in : c3ExternalIds AND Type__c = 'UI Card'];

            for(ASF_Integration__c asfCaseInteg : specificIntegrations){
                if(!uiCardIntegrationMap.containsKey(asfCaseInteg.C3ExternalId__c)){
                    uiCardIntegrationMap.put(asfCaseInteg.C3ExternalId__c, new List<ASF_Integration__c>());
                }
                uiCardIntegrationMap.get(asfCaseInteg.C3ExternalId__c).add(asfCaseInteg);
            }

            for(Case cs : newCases){
                if(cs.Business_Unit__c == 'ABHFL' && cs.Technical_Source__c != 'API' && uiCardIntegrationMap.containsKey(cs.CCC_External_Id__c)){
                    ASF_CaseFrameworkHelper.runIntegrations(cs, uiCardIntegrationMap.get(cs.CCC_External_Id__c));
                }
            }
        }
    }
    //Dhinesh - to Send Tracking Links
    public static void sendTrackingLink(Case caseRec){
        List<String> validSubTypes = new List<String>{'qbccdd01', 'hfl060','RRSDPRSHFC01'};
        Id caseId = caseRec.Id; 
    	Case caseRecord = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c,Short_URL__c
                       FROM Case WHERE Id = :caseId];
        if(caseRecord.Short_URL__c != NULL && validSubTypes.contains(caseRecord.CCC_External_Id__c)){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                  NULL, 
                                                                  ABHFL_Constants.TRACKING_LINK_SMS, 
                                                                  false);
        }
    }
    //Dhinesh - to store multi lan in a field and send payment confirmation mail
    public static void storeMultipleLANs(Case caseRec){
        Case caseRecord = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c,Short_URL__c
                       FROM Case WHERE Id = :caseRec.Id];
        List<ABHFL_Asset_Detail__c> relatedAssets = [SELECT Id, Asset__r.LAN__c,Revised_ROI__c
                                                   FROM ABHFL_Asset_Detail__c
                                                   WHERE Case__c=:caseRec.Id];
        ABHFL_Case_Detail__c caseDetail = [SELECT Id,Masked_Full_LANs__c,Payment_Status__c FROM ABHFL_Case_Detail__c WHERE Id =:caseRec.ABHFL_Case_Detail__c LIMIT 1];
        String result = '';
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
		caseDetail.Masked_Full_LANs__c = result;
        update caseDetail;
        if(caseDetail.Masked_Full_LANs__c != NULL && caseDetail.Payment_Status__c == 'Payment Received'){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                  ABHFL_Constants.MULTIPLELAN_PAYMENT_RECEIVED_EMAIL, 
                                                                  ABHFL_Constants.MULTIPLELAN_PAYMENT_RECEIVED_SMS, 
                                                                  false);
        }
     
    }
    public static void sendPrclsStatementclosure(Case caseRec){
        Case caseRecord = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c, No_Auto_Communication__c,ABHFL_Case_Detail__c
                       FROM Case WHERE Id = :caseRec.Id];
        List<ABHFL_Asset_Detail__c> relatedAssets = [SELECT Id, Asset__r.LAN__c,Revised_ROI__c
                                                   FROM ABHFL_Asset_Detail__c
                                                   WHERE Case__c=:caseRec.Id];
        ABHFL_Case_Detail__c caseDetail = [SELECT Id,Masked_Full_LANs__c FROM ABHFL_Case_Detail__c WHERE Id =:caseRecord.ABHFL_Case_Detail__c LIMIT 1];
        String result = '';
		for (Integer i = 0; i < relatedAssets.size(); i++) {
    		ABHFL_Asset_Detail__c assetDetail = relatedAssets[i];
    		String maskedLan = 'xxxxxx' + assetDetail.Asset__r.LAN__c.substring(Math.max(0, assetDetail.Asset__r.LAN__c.length() - 4));
        	if (i == relatedAssets.size() - 1) {
        		 result += ' and ' + maskedLan;
    		} else {
        		if (i > 0) {
            		result += ', ';
        		}
        	result += maskedLan;
    		}
		}
		caseDetail.Masked_Full_LANs__c = result;
        update caseDetail;
        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                  ABHFL_Constants.MULTIPLELAN_PRCLS_STATEMENT_CLOSUREEMAIL, 
                                                                  ABHFL_Constants.MULTIPLELAN_PRCLS_STATEMENT_CLOSURESMS, 
                                                                  true);
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

    public static Case createCases(String clientCode, String lan, String ccc, String source, String techSource, Id parentCaseId) {
        Case caseRecord = new Case();
        caseRecord.Business_Unit__c = 'ABHFL';
        caseRecord.Client_Code_Text__c = clientCode;
        caseRecord.Source__c = source;
        caseRecord.Technical_Source__c = techSource;
        caseRecord.CCC_External_Id__c = ccc;
        caseRecord.LAN__C = lan;
        caseRecord.parentId = parentCaseId;
        return caseRecord;
    }
    
    public static void insertCases(List<Case> caseList) {
ASF_CaseTriggerModularHelper.populateFrameworkFieldsForCase(caseList,null);
        if(!caseList.isempty()){
             insert caseList;
        }
    }
    
}
