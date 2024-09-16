/**
* @description       : BSLI BeforeUpdateTrigger Logic Before ASF Code
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 09-02-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ABSLI_BeforeUpdateTriggerLogic {
    /**
* @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
* updated. This is the parent method
* @param newMap
* @param oldMap
*/
    public Static Map<Id, Case> absliCasesAdditionalFields;
    public static void executeBeforeLogic(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;
        Map<Id,Case> mAbsliCases = new Map<Id,Case>();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newMap.values());
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            Map<Id,Case> frameworkCases = new Map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            for(Case caseRec : frameworkCases.values()){
                if(caseRec.Business_Unit__c == ASF_Constants.ABSLI_BU){
                        mAbsliCases.put(caseRec.Id,caseRec);
                    }
            }
        }
        
        if(!mAbsliCases.isEmpty()){
            absliCasesAdditionalFields = new Map<Id, Case>([SELECT Id,Asset.Issue_Date__c,ABSLI_Case_Detail__c,CCC_External_Id__c, 
                                                            ABSLI_Case_Detail__r.To_date__c, ABSLI_Case_Detail__r.From_date__c,CaseNumber,ABSLI_Case_Detail__r.IRDAI_Token_Number__c,Nature__c,Stage__c,Technical_Source__c,
                                                            ABSLI_Case_Detail__r.Complaint_Category__c,ABSLI_Case_Detail__r.Resolve_case__c,IRDAI_Token_Number__c,IGMS_Complaint_Type_Code__c ,FTR__c,ABSLI_Case_Detail__r.IGMS_type_of_policy__c,ABSLI_Case_Detail__r.Before_3_PM__c,ABSLI_Case_Detail__r.Branch_Receive_Date__c
                                                            FROM Case 
                                                            WHERE Id IN :mAbsliCases.keySet()]);
            System.debug('Inside ABSLI before Update Trigger logic');
            System.debug(absliCasesAdditionalFields);
            //ABSLI_BeforeUpdateTriggerLogic.autoResolveFtrCases(mAbsliCases.values(), oldMap);
            ABSLI_BeforeUpdateTriggerLogic.validateFromDateToDate(mAbsliCases.values(), oldMap, newMap);
            ABSLI_BeforeUpdateTriggerLogic.validateTasks(mAbsliCases.values(), oldMap, newMap);
            ABSLI_BeforeUpdateTriggerLogic.checkIfMandatoryChecklistNotCompleted(mAbsliCases, oldMap);
            ABSLI_BeforeUpdateTriggerLogic.checkComplaintApplicability(newMap.values(), oldMap, newMap);
        }  
    }
    /**
* @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
* updated. If the case is marked as FTR, the case status is updated to 'Resolved'
* @param absliCases
* @param oldMap

public static void autoResolveFtrCases(List<Case> absliCases, Map<Id, Case> oldMap){
if(!absliCases.isEmpty()){
for(Case caseRec : absliCases){
if(caseRec.MoveToNext__c != oldMap.get(caseRec.Id).MoveToNext__c 
&& caseRec.MoveToNext__c == true && caseRec.FTR__c == true){
caseRec.MoveToNext__c = false;
caseRec.Status = ASF_Constants.ONCREATECLOSESTATUS;
caseRec.Stage__c = ASF_Constants.ONCREATECLOSESTAGE;
}
}
}   
}*/
    
    /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
     * moved to next stage and skip to stage. It validates if any open checklist is pending and throws validation error
     * @param newMap
     * @param oldMap
     */
    public static void validateTasks(List<Case> absliCases, Map<Id, Case> oldMap, Map<Id, Case> newMap){
        Map<Id, Case> eligibleCases = new Map<Id, Case>();
        if(!absliCases.isEmpty()){
            for(Case caseRec : absliCases){
                if((caseRec.MoveToNext__c != oldMap.get(caseRec.Id).MoveToNext__c && caseRec.MoveToNext__c == true) 
                   || (caseRec.MoveToNext__c == oldMap.get(caseRec.Id).MoveToNext__c && caseRec.MoveToNext__c == false
                       && caseRec.CCC_External_Id__c == oldMap.get(caseRec.Id).CCC_External_Id__c
                       && caseRec.Reopened_DateTime__c == oldMap.get(caseRec.Id).Reopened_DateTime__c
                       && caseRec.Reject_Case__c == oldMap.get(caseRec.Id).Reject_Case__c
                       && caseRec.Is_Duplicate__c == oldMap.get(caseRec.Id).Is_Duplicate__c
                       && caseRec.Stage__c != oldMap.get(caseRec.Id).Stage__c
                       && caseRec.pending_clarification__c == false)){
                           
                           eligibleCases.put(caseRec.Id, caseRec);
                       }
            }
            Map<Id,AggregateResult> mCountOfNotCompletedTaskOnCase = new Map<Id,AggregateResult>(
                [SELECT WhatId Id, COUNT(ID) FROM Task 
                 WHERE Status NOT IN ('Completed','Rejected')
                 AND WhatId =: eligibleCases.keySet()
                 GROUP BY WhatId
                 HAVING COUNT(ID) > 0]);
            
            for(Case caseRec : eligibleCases.values()){
                Map<Id, Set<String>> skipperFlagMap = ASF_CaseTriggerModularHelper.getSkipperFlagMap();
                if(mCountOfNotCompletedTaskOnCase.containsKey(caseRec.Id) && 
                   !(skipperFlagMap.containsKey(caseRec.Id) && skipperFlagMap.get(caseRec.Id).contains(ASF_Constants.SKIP_VALIDATE_TASKS))){
                       Case caseError = newMap.get(caseRec.Id);
                       caseError.addError(System.Label.Incomplete_Tasks_Error_Message);
                       newMap.put(caseRec.Id,caseError);
                   }
            }
        }   
    }
    
    /**
* @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
* updated. From Date and To Date Validation.
* @param absliCases
* @param oldMap
*/
    public static void validateFromDateToDate(List<Case> absliCases, Map<Id, Case> oldMap, Map<Id, Case> newMap){
        List<String> validSubTypes = new List<String>{'PEMT042', 'PEMT024'};
        List<String> validSubTypesBefore3PM = new List<String>{'PNFT042','PPAY001','PPAY008'};
                if(!absliCases.isEmpty()){
                    for (Case caseRec : absliCasesAdditionalFields.values()) {
                        System.debug(caseRec.ABSLI_Case_Detail__r.To_date__c);
                        System.debug(caseRec.ABSLI_Case_Detail__r.From_date__c);
                        // Check if the Case record is related to ABSLI business unit
                        if (caseRec.ABSLI_Case_Detail__c != null  && validSubTypes.contains(caseRec.CCC_External_Id__c)) {
                            System.debug('Inside validate date: ' + caseRec.Asset.Issue_Date__c);
                            Date issueDate = caseRec.Asset.Issue_Date__c;
                            Date toDate = caseRec.ABSLI_Case_Detail__r.To_date__c;
                            Date fromDate = caseRec.ABSLI_Case_Detail__r.From_date__c;
                            
                            // Validate dates
                            if (toDate < issueDate || fromDate < issueDate) {
                                // Add an error message to the Case record
                                Case caseError = newMap.get(caseRec.Id);
                                caseError.addError('To Date/From Date should be greater than or equal to the Policy Issued Date');
                                newMap.put(caseRec.Id,caseError);
                            }
                            if (fromDate > toDate) {
                                // Add an error message to the Case record
                                Case caseError = newMap.get(caseRec.Id);
                                caseError.addError('From Date should not be greater than To Date');
                                newMap.put(caseRec.Id,caseError);
                            }

                        }
                        //Validate before3PM scenario
                        if (caseRec.ABSLI_Case_Detail__c != null  && validSubTypesBefore3PM.contains(caseRec.CCC_External_Id__c) && caseRec.Stage__c == 'Open') {
                            Date today = Date.today();
                            String before3PM = caseRec.ABSLI_Case_Detail__r.Before_3_PM__c;
                            Date branchReceiveDate = caseRec.ABSLI_Case_Detail__r.Branch_Receive_Date__c;
                            Case caseError = newMap.get(caseRec.Id);
                            if(before3PM != null && branchReceiveDate != null){
                                switch on before3PM {
                                    when 'No' {
                                        Date expectedDate = today.addDays(1);
                                        if (branchReceiveDate != expectedDate) {
                                            caseError.addError('Branch received Date should be next day, if after 3PM');
                                        }
                                    }
                                    when 'Yes' {
                                        if (branchReceiveDate != today) {
                                            caseError.addError('Branch received Date should be Today, if before 3PM');
                                        }
                                    }
                                    when else {
                                        caseError.addError('Invalid value for Before 3 PM');
                                    }
                                }  
                            }
                        }
                   }  
                }
    }
    /**
* @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
* updated. This marks case as Unresolved based on the checklist value for certain "Request" cases
* @param mAbsliCases
* @param oldMap
*/
	public static void checkIfMandatoryChecklistNotCompleted(Map<Id, Case> mAbsliCases, Map<Id, Case> oldMap){
        Map<Id, Case> eligibleCases = new Map<Id, Case>();
        if(mAbsliCases.keyset().size()>0){
            for(Case c : mAbsliCases.values()){
                System.debug('Dhin'+oldMap.get(c.Id).MoveToNext__c );
                System.debug('2'+c.MoveToNext__c);
                if(c.MoveToNext__c != oldMap.get(c.Id).MoveToNext__c && c.MoveToNext__c == true && c.Technical_Source__c != 'API' && c.Nature__c == 'Request'){
                    eligibleCases.put(c.Id, c);
                }
            }
        }
        // CHECK IF OPEN CHECKLIST.
        // IF COUNT OF RECORD IS > 0, SET REJECT_CASE__C to TRUE
        if(!eligibleCases.isEmpty()){
            Map<Id,AggregateResult> mCountOfNotCompletedChecklistOnCase = new Map<Id,AggregateResult>(
                [SELECT Case__c Id, COUNT(ID) FROM ASF_Checklist__c 
                 WHERE Status__c IN: ABSLI_Constants.CHECKLIST_FAILURE_STATUS
                                                      AND Case__c =: eligibleCases.keySet()
                                                      AND Mandatory__c = TRUE
                 GROUP BY Case__c
                 HAVING COUNT(ID) > 0]);
            for(Case c : eligibleCases.values()){
                if(mCountOfNotCompletedChecklistOnCase.containsKey(c.Id)){
                        c.Reject_Case__c = true;
                        c.Auto_Rejected__c = true;
                        c.MoveToNext__c = false;
                }
            }
        }              
    }
    
    /**
* @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
* updated. To Restrict Complaint Category Type for Non-IGMS Complaints.
* @param absliCases
* @param oldMap
*/
    public static void checkComplaintApplicability(List<Case> absliCases, Map<Id, Case> oldMap, Map<Id, Case> newMap) {
        Set<String> externalIds = new Set<String>();
        for (Case caseRec : absliCasesAdditionalFields.values()) {
            if (caseRec.CCC_External_Id__c != null) {
                externalIds.add(caseRec.CCC_External_Id__c);
            }
        }
        
        // Query ASF_Case_Category_Config__c using the external IDs
        Map<String, ASF_Case_Category_Config__c> configMap = new Map<String, ASF_Case_Category_Config__c>();
        for (ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c, IGMS_Code__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :externalIds]) {
            configMap.put(config.CCC_External_Id__c, config);
        }
        Map<String,Map<String,Set<String>>> mClassificationIGMS = ABSLI_IGMSClassificationUtility.getIGMSClassification();
        for (Case caseRec : absliCasesAdditionalFields.values()) {
            if (caseRec.CCC_External_Id__c != null && configMap.containsKey(caseRec.CCC_External_Id__c)) {
                ASF_Case_Category_Config__c config = configMap.get(caseRec.CCC_External_Id__c);
                System.debug(config.IGMS_Code__c);
                System.debug(caseRec.ABSLI_Case_Detail__r.Resolve_case__c);
                System.debug(caseRec.ABSLI_Case_Detail__r.Complaint_Category__c);
                if (config.IGMS_Code__c == '#N/A' &&
                    caseRec.ABSLI_Case_Detail__r.Complaint_Category__c == 'Complaint' &&
                    caseRec.Nature__c == 'Complaint' && 
                    caseRec.Technical_Source__c != 'API') {
                        Case caseError = newMap.get(caseRec.Id);
                        caseError.addError('Category Type of "Complaint" is not applicable for Non-IGMS cases');
                        newMap.put(caseRec.Id,caseError);
                    }
                if (config.IGMS_Code__c != '#N/A' &&
                    caseRec.ABSLI_Case_Detail__r.Complaint_Category__c != 'Complaint' &&
                    caseRec.ABSLI_Case_Detail__r.IRDAI_Token_Number__c != null &&
                    caseRec.Nature__c == 'Complaint' && 
                    caseRec.Technical_Source__c != 'API') {
                        Case caseError = newMap.get(caseRec.Id);
                        caseError.addError('Category type cannot be changed for IGMS Synced cases');
                        newMap.put(caseRec.Id,caseError);
                    }
                if(caseRec.IGMS_Complaint_Type_Code__c != null &&
                   caseRec.Nature__c == 'Complaint' && 
                    caseRec.ABSLI_Case_Detail__r.IRDAI_Token_Number__c != null && 
                   caseRec.Technical_Source__c != 'API'){
                	ABSLI_IGMSClassificationUtility.validationWrapper returnWrapper= ABSLI_IGMSClassificationUtility.validateCurrentSelection(mClassificationIGMS, caseRec);
                	if(returnWrapper.bErrorOccured){
                           Case caseError = newMap.get(caseRec.Id);
                    	String errorMessage = returnWrapper.errorMessage;
                    	caseError.addError(errorMessage);
                       }
                       
                   }
            }
        }
    }
    
    public static void checkCreateCaseValidations(List<Case> absliCases, Map<Id, Case> oldMap){
        Set<String> issueCodes = new Set<String>();
        List<Case> validCases = new List<Case>();
        Map<Id,Asset> caseIdVsPolicy = new Map<Id,Asset>();
        Set<Id> policyIds = new Set<Id>();
        Id interactionRecTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        for(Case c: absliCases){
            if(c.Business_Unit__c=='ABSLI' && c.Technical_Source__c=='LWC' && c.RecordTypeId==frameworkRecordTypeId && 
               oldMap.get(c.Id).RecordTypeId == interactionRecTypeId && c.Preframework_to_Framework_FromUI__c == true){
                   issueCodes.add(c.CCC_External_Id__c);
                   validCases.add(c);
                   policyIds.add(c.AssetId);
               }
        }
        Map<Id, Asset> policyMap = new Map<Id, Asset>([SELECT Id, Status FROM Asset WHERE Id IN :policyIds]);
        for(Case c: validCases){
            if(policyMap.containsKey(c.AssetId)){
                caseIdVsPolicy.put(c.Id,policyMap.get(c.AssetId));
            }
        }
        if(issueCodes.size()>0 && !caseIdVsPolicy.isEmpty()){
            Map<String, ABSLI_Create_Case_Validations__mdt> issueCodeVsMdt = new Map<String, ABSLI_Create_Case_Validations__mdt>();
            List<ABSLI_Create_Case_Validations__mdt> validationMdtList = [SELECT Label,Business_Unit__c,Issue_Code__c,
                                                                          Operator__c,Asset_Values__c,Error_Message__c
                                                                          FROM ABSLI_Create_Case_Validations__mdt
                                                                          WHERE Business_Unit__c ='ABSLI'
                                                                          AND Issue_Code__c IN :issueCodes];
            for (ABSLI_Create_Case_Validations__mdt record : validationMdtList) {
                issueCodeVsMdt.put(record.Issue_Code__c, record);
            }
            
            for(Case cs: validCases){
                if(issueCodeVsMdt.containsKey(cs.CCC_External_Id__c) &&
                   issueCodeVsMdt.get(cs.CCC_External_Id__c).Business_Unit__c=='ABSLI')
                {
                    List<String> policyStatuses = issueCodeVsMdt.get(cs.CCC_External_Id__c).Asset_Values__c.split(':');
                    String oprtr = issueCodeVsMdt.get(cs.CCC_External_Id__c).Operator__c;
                    switch on oprtr{
                        when 'IN'{
                            if((caseIdVsPolicy.get(cs.Id).Status!=null) && (!policyStatuses.contains(caseIdVsPolicy.get(cs.Id).Status.replaceAll('\\s*,\\s*', ',')))){
                                cs.addError(issueCodeVsMdt.get(cs.CCC_External_Id__c).Error_Message__c);
                            }
                        }
                        when 'NOT IN'{
                            if((caseIdVsPolicy.get(cs.Id).Status!=null) && (policyStatuses.contains(caseIdVsPolicy.get(cs.Id).Status.replaceAll('\\s*,\\s*', ',')))){
                                cs.addError(issueCodeVsMdt.get(cs.CCC_External_Id__c).Error_Message__c);
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    //custom exception class
    public class MyCustomException extends Exception {}
}
