/*********************************************************
*Class        :  ASF_RelateDuplicateCaseController
*Author       :  Salesforce
*Description  :  This class is called from the asf_RelateDuplicateCase lwc component
                to link the parentId to case and to mark it as duplicate
*********************************************************/
public with sharing class ASF_RelateDuplicateCaseController {
   
    @AuraEnabled(cacheable=false)
    public static String updateCaseParent(Id caseRecordId, Id parentId, Boolean isDuplicate) {
        
        String result = 'Success';
        Case caseRec = new Case();
        caseRec.Id = caseRecordId;
        caseRec.parentId = parentId;
        if(isDuplicate){
            caseRec.Is_Duplicate__c = isDuplicate;
            caseRec.status = ASF_Constants.DUPLICATESTATUS;
            caseRec.Stage__c = ASF_Constants.DUPLICATESTAGE;
            caseRec.Rejected_Reason__c = 'Duplicate Case';
        }
        
        Database.SaveResult saveResult = Database.update(caseRec, false);
        if (!saveResult.isSuccess()) {
            result = saveResult.getErrors()[0].getMessage();
        } 
        
        return result;
    }   
}