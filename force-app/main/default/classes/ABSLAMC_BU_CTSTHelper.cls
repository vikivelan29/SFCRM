/*********************************************************
*@Class        :  ABSLAMC_BU_CTSTHelper
*@Author       :  Santosh
*@Created Date :  8/30/2024
*@Last Modified:  8/30/2024
*@description  :  Class for ABSLAMC BU Specific Methods. 
*********************************************************/

public with sharing class ABSLAMC_BU_CTSTHelper {
    
    /**
* @param newCaseList - list of new value cases from trigger
* @param olCasesMap - Map of old value cases from trigger
* @return null
* @description - calling this method in Before update trigger to Restring agent's backward movement from Stage 3 to Stage 1 for ABSLAMC BU for Journey 5 - US PR1030924-53
*/
    public static void restrictBackStageMovementFromStage3ToSatage1(Map<Id, Case> newCaseMap, Map<Id, Case> oldCasesMap){
        String backstageError = System.label.ABSLAMC_Back_Stage_Movement_Error;
        for(Case currentCase: newCaseMap.values()){
            Case oldCase = oldCasesMap.get(currentCase.Id);
            if(currentCase.Stage__c != oldCase.Stage__c  && currentCase.moved_back__c && currentCase.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU
               && oldCase.Stage__c == ABSLAMC_Constants.REPLY_RECEIVED_FROM_APP_SUPPORT && currentCase.Stage__c == ABSLAMC_Constants.OPEN_STAGE){
                   currentCase.addError(backstageError);
               }
        }
    }
    
    
    /**
* @param newCaseList - list of new value cases from trigger
* @param olCasesMap - Map of old value cases from trigger
* @return null
* @description - calling this method in Before update trigger to Restring agent's forward movement to 'Reply Recieved from Cams' stage for ABSLAMC CAMS cases
*/
    public static void restrictForwardStageMovementToThirdStageCAMS(Map<Id, Case> newCaseMap, Map<Id, Case> oldCasesMap){
        Profile currentUserProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];      
        
        String forwardstageError = System.label.ABSLAMC_Forward_Movement_Error ;
        for(Case currentCase: newCaseMap.values()){
            Case oldCase = oldCasesMap.get(currentCase.Id);
            if(currentCase.Stage__c != oldCase.Stage__c  && currentCase.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU
               && currentCase.Stage__c == ABSLAMC_Constants.REPLYFROMCAMS && oldCase.Stage__c == ABSLAMC_Constants.CAMSPENDINGSTATUS 
               && currentUserProfile.Name == 'ABSLAMC Base User'){
                   currentCase.addError(forwardstageError);
               }
        }
    }
    
    /**
* @param newCaseList - list of new value cases from trigger
* @return null
* @description - calling this method in Before insert trigger to assign the correct values for the case which is creatig from the MF360 
* (creating AMC Case details record, assigning type, subtype, nature on basis of ccc extenral id, also assigning an asset & customer on the basis of folio & client code..)
*/
    /*public static void populateBasicInformationOfCaseForMF360AMC(List<Case> newItems) {
map<Integer, Case> integerWithCase = new map<Integer, Case>();
map<Integer, ABSLAMC_Case_Detail__c>  integerWithCaseDetails = new  map<Integer, ABSLAMC_Case_Detail__c>();
Integer i = 0;
for(Case caseObj: newItems){
i++;
if( checkConditionForMF360(caseObj) ){
ABSLAMC_Case_Detail__c caseDetails = new ABSLAMC_Case_Detail__c();
if(!String.isEmpty(caseObj.Case_Details_JSON__c)){
caseDetails = (ABSLAMC_Case_Detail__c)JSON.deserialize(caseObj.Case_Details_JSON__c.replace('\'','"'), Type.forName('ABSLAMC_Case_Detail__c'));
}

integerWithCase.put(i, caseObj);
integerWithCaseDetails.put(i, caseDetails);
}
}

if(!integerWithCaseDetails.isEmpty()){
ASF_TriggerSkipperUtility.markTriggerRun('ABSLAMC_Case_Detail__c');
insert integerWithCaseDetails.values();
ASF_TriggerSkipperUtility.resetTriggerRun('ABSLAMC_Case_Detail__c');
for(integer key : integerWithCase.keySet() ){
case currentcase = integerWithCase.get(key);
currentcase.ABSLAMC_Case_Detail__c = integerWithCaseDetails.get(key).Id;
}
}
}

public static Boolean checkConditionForMF360(Case obj){
return obj.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU && obj.ABSLAMC_Case_Detail__c == null;
}*/
    
    /**
* @param newCaseList - list of new value cases from trigger
* @return null
* @description - this method is used to validate if the case is in mandatory approval stage or not
*/
    public static void validateManualApproval(Map<Id, Case> newMapCase, Map<Id, Case> oldMapCase) {
        System.debug('inside mandatory approval niks1');
        
        Set<String> statusToCheck = new Set<String>{ABSLAMC_Constants.CAMSPENDINGSTATUS};
            Map<Id, Case> amcCAMSApprovalSpecificCases = new Map<Id, Case>();
        Set<Id> caseIds = new Set<Id>();
        Map<Id, List<ASF_Case_Approv__c>> caseApprovalsMap = new Map<Id, List<ASF_Case_Approv__c>>();
        Map<Id, String> caseIdToCCCMap = new Map<Id, String>();
        Map<Id, Set<String>> caseIdToSkipperFlag = new Map<Id, Set<String>>();
        string mandatoryAppErrMsg = label.ABSLAMC_MandatoryApprovalRequired;
        string nonMandatoryAppErrMsg = label.ABSLAMC_NonMandatoryAppErrMsg;
        string atleastOneApprRecordErrMsg = label.ABSLAMC_NoApprovalRecordsFound;
        string approvalReqErrMsg = 'Approval is required, but no approved or rejected records found'; // New error message
        Set<Id> relatedCaseDetailRecordIds = new Set<Id>();
        Map<Id, ABSLAMC_Case_Detail__c> relatedBRecordsMap = new Map<Id, ABSLAMC_Case_Detail__c>();

        
        for (Case caseRec : newMapCase.values()) {
            Case oldCaseRec = oldMapCase.get(caseRec.Id);
            
            // Check if the Stage__c is moving from 2 to 3
            if (caseRec.Stage__c == ABSLAMC_Constants.CAMSPENDINGSTATUS && oldCaseRec.Stage__c == ABSLAMC_Constants.CAMSAPPROVALSTAGE && 
                caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU && 
                statusToCheck.contains(caseRec.Stage__c)) {
                    
                    amcCAMSApprovalSpecificCases.put(caseRec.Id, caseRec); 
                    if (String.isNotBlank(caseRec.CCC_External_Id__c)) {
                        caseIdToCCCMap.put(caseRec.Id, caseRec.CCC_External_Id__c); 
                    }
                    if (caseRec.ABSLAMC_Case_Detail__c != null) { //
                        relatedCaseDetailRecordIds.add(caseRec.ABSLAMC_Case_Detail__c);
                    }
                }
        }
        
        if(!relatedCaseDetailRecordIds.isEmpty()){
        relatedBRecordsMap = new Map<Id, ABSLAMC_Case_Detail__c>([
            SELECT Id, Approval_Required__c 
            FROM ABSLAMC_Case_Detail__c 
            WHERE Id IN :relatedCaseDetailRecordIds
        ]);
    }
        
        System.debug('Case IDs for approval check niks2: ' + caseIdToCCCMap);
        
        if (!caseIdToCCCMap.isEmpty()) {
            // Fetch the relevant stage configuration records
            List<ASF_Case_Stage_Config__c> stageConfigs = [
                SELECT Id, Mandatory_Approval__c, Case_Category_Config__r.CCC_External_Id__c, StageName__c, Is_Approval_Stage__c 
                FROM ASF_Case_Stage_Config__c  
                WHERE Case_Category_Config__r.CCC_External_Id__c IN :caseIdToCCCMap.values() 
                AND StageName__c = :ABSLAMC_Constants.CAMSAPPROVALSTAGE
            ];
            
            System.debug('inside mandatory approval niks3' + stageConfigs);
            
            if (!stageConfigs.isEmpty()) {
                List<ASF_Case_Approv__c> approvalRecords = [
                    SELECT Id, Approval_Status__c, SR__c, CreatedDate
                    FROM ASF_Case_Approv__c
                    WHERE SR__c IN :caseIdToCCCMap.keySet()
                    ORDER BY CreatedDate DESC
                ];
                System.debug('inside mandatory approval niks4' + approvalRecords);    
                
                for (ASF_Case_Approv__c approval : approvalRecords) {
                    if (!caseApprovalsMap.containsKey(approval.SR__c)) {
                        caseApprovalsMap.put(approval.SR__c, new List<ASF_Case_Approv__c>());
                    }
                    caseApprovalsMap.get(approval.SR__c).add(approval);
                }
            }
            System.debug('inside mandatory approval niks5' + caseApprovalsMap);
            
            for (ASF_Case_Stage_Config__c stageConfig : stageConfigs) {
                System.debug('inside mandatory approval niks6' + stageConfig.Case_Category_Config__r.CCC_External_Id__c);
                
                Id caseId = null;
                for (Id id : caseIdToCCCMap.keySet()) {
                    if (stageConfig.Case_Category_Config__r.CCC_External_Id__c.equals(caseIdToCCCMap.get(id))) {
                        caseId = id;
                        break;
                    }
                }
                
                Case caseRec = amcCAMSApprovalSpecificCases.get(caseId);
                
                if (caseRec != null) {
                    List<ASF_Case_Approv__c> approvals = caseApprovalsMap.get(caseRec.Id);
                    ABSLAMC_Case_Detail__c relatedBRec = relatedBRecordsMap.get(caseRec.ABSLAMC_Case_Detail__c);
                    if (relatedBRec != null && relatedBRec.Approval_Required__c == 'Yes') {
                        Boolean validApprovalExists = false;
                        
                        if (approvals != null && !approvals.isEmpty()) {
                            ASF_Case_Approv__c latestApproval = approvals[0];
                            
                            if (latestApproval.Approval_Status__c == ABSLAMC_Constants.APPROVEDSTATUS){
                                validApprovalExists = true;
                            }
                        }
                        
                        if (!validApprovalExists) {
                            caseRec.addError(approvalReqErrMsg);
                        }
                    }
                    
                    if (approvals != null && !approvals.isEmpty()) {
                        ASF_Case_Approv__c latestApproval = approvals[0];
                        
                        if (stageConfig.Mandatory_Approval__c && stageConfig.Is_Approval_Stage__c) {
                            // Check if the latest approval record is approved
                            if (latestApproval.Approval_Status__c != ABSLAMC_Constants.APPROVEDSTATUS) {
                                caseRec.addError(mandatoryAppErrMsg);
                            }
                        } else if (!stageConfig.Mandatory_Approval__c && stageConfig.Is_Approval_Stage__c) {
                            // Check if the latest approval record is approved or recalled
                            if (latestApproval.Approval_Status__c != ABSLAMC_Constants.APPROVEDSTATUS && latestApproval.Approval_Status__c != ABSLAMC_Constants.RECALLEDSTATUS) {
                                caseRec.addError(nonMandatoryAppErrMsg);
                            } else { 
                                caseIdToSkipperFlag.put(caseRec.Id, new Set<String>{ASF_Constants.SKIP_APPROVAL_CHECKS});}
                        }
                    } else {
                        if (stageConfig.Mandatory_Approval__c && stageConfig.Is_Approval_Stage__c) {
                            // No approval records found for mandatory approval stage, add an error
                            caseRec.addError(atleastOneApprRecordErrMsg);
                        }
                    }
                }
                if(!caseIdToSkipperFlag.isEmpty()){
                    ASF_CaseTriggerModularHelper.setManualSkipperFlags(caseIdToSkipperFlag, null);
                }
            }
        }
    }
    
    /**
    * @param newCaseList - list of new value cases from trigger
    * @param olCasesMap - Map of old value cases from trigger
    * @return null
    * @description - calling this method in Before update trigger to assign to the correct LOB of the Case LOB - Bug-200 AMC bug tracker
    */
    public static void CheckQueueAssignementSpecificToLOB(Map<Id, Case> newCaseMap, Map<Id, Case> oldCasesMap){
        list<String> queueIdList = new List<String>();
        for (Case caseRec : newCaseMap.values()) {
            Case oldcase = oldCasesMap.get(caseRec.Id);
            if(caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU && caseRec.OwnerId != oldCase.OwnerId && !String.valueOf(caseRec.OwnerId).startsWith('005') ){
                queueIdList.add(caseRec.OwnerId);
            }
        }
        if(queueIdList.size()>0){
            map<String, String> queueIdwithDeveloperName = new map<String, String>();
            for(Group qObj : [SELECT Id, DeveloperName  FROM Group where Type = 'Queue' AND Id IN : queueIdList]){
                queueIdwithDeveloperName.put(qObj.Id, qObj.DeveloperName);
            }
            for(Case caseRec : newCaseMap.values()) {
            Case oldcase = oldCasesMap.get(caseRec.Id);
            if(caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU && caseRec.OwnerId != oldCase.OwnerId && !String.valueOf(caseRec.OwnerId).startsWith('005') ){
                if(queueIdwithDeveloperName.keySet().contains(caseRec.OwnerId)){
                    String[] qDevNameArr = queueIdwithDeveloperName.get(caseRec.OwnerId).split('_');
                    if(qDevNameArr[1] !=caseRec.Line_Of_Business__c){
                        caseRec.addError(System.label.ABSLAMC_Queue_error_message);
                    }
                }
            }
        }
        }
    }
    
}