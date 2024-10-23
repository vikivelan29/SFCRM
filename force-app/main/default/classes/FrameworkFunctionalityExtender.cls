/****************************************************************************************************************
  * Author           - Anirudh Raturi
  * Date             - 04-Jan-2024
  *****************************************************************************************************************/

public with sharing class FrameworkFunctionalityExtender implements ASF_FrameworkFunctionalityExtender{
    
    /**
     * Below method is used to populate BU specific fields
     * during convertion of preframework to framework
     */
    public SObject populateBUSpecificFields(SObject record, SObject cccRecObj) {
        
        String sobjName = String.valueof(record.getSObjectType());
        ASF_Case_Category_Config__c cccRec =  (ASF_Case_Category_Config__c) cccRecObj;
        String cccNature = String.isNotBlank(cccRec.Nature__c) ? cccRec.Nature__c : '';
        Case caseRec = ASF_CaseUIController.caseRecord;

        if(sobjName == 'ABHFL_Case_Detail__c' && cccNature == 'Complaint') {
            User objUser = [SELECT Id, Business_Unit__c, Source_Code__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
            String userSourceCode = objUser.Source_Code__c;
            String strBusinessUnit = String.isNotBlank(objUser.Business_Unit__c) ? objUser.Business_Unit__c.trim() :'';

            List<LOBMappingDetails__mdt> lstLOBMapping = new List<LOBMappingDetails__mdt>();
            lstLOBMapping  = [SELECT  Id, Complaint_Type__c
                            FROM LOBMappingDetails__mdt WHERE 
                            LOB__c =:strBusinessUnit AND Source_Code__c =:userSourceCode AND
                            IsActive__c = true 
                            LIMIT 1];


            String complaintType = lstLOBMapping[0].Complaint_Type__c;

            ABHFL_Case_Detail__c abhflCaseDet = (ABHFL_Case_Detail__c) record;
            abhflCaseDet.Complaint_Type__c = complaintType;
            record = abhflCaseDet;
        } 

        if(sObjName == ASF_Constants.ABSLI_CASE_EXTENSION_OBJ_NAME && caseRec.Origin == ASF_Constants.ABSLI_CASE_ORIGIN_EMAIL){
            ABSLI_Case_Detail__c caseDetail = (ABSLI_Case_Detail__c) record;
            caseDetail.Source_Request_submitted_by__c = ABSLI_Constants.EMAIL_SOURCE_REQ_BY;
            record = caseDetail;
        }
        system.debug('record--'+record);      
        return record;
    }
}
