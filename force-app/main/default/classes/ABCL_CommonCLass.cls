/*********************************************************
*Class        :  ABCL_CommonCLass
*Author       :  Anirudh Raturi
*Created Date :  15/02/2024
*Last Modified:  15/02/2024
*Description  :  Common class for all the LOB's
*********************************************************/

public with sharing class ABCL_CommonCLass {

    /****************************************************************************************************************
    * @Function - prepopulateCaseFlds
    * @param newItems -  list of sobject records.
    * @return - void .
    * @Description - This method pre-populates fields on Case.
    *****************************************************************************************************************/
    public void prepopulateCaseFlds(List<Sobject> newItems) {

        List<Case> newCaseList = (List<Case>)newItems;
        prepopulateCaseFldsOnBasisOfBussinessUnit(newCaseList);
    }

    /****************************************************************************************************************
    * @Function - prepopulateCaseFldsOnBasisOfBussinessUnit
    * @param newItems -  list of case records.
    * @return - void .
    * @Description - This method pre-populates BusinessHoursId field on Case on the basis of Business Unit field.
    * Note - Please use the name of Business Unit of Case in Business Hour Name field of BusinessHours object
    *****************************************************************************************************************/
    public void prepopulateCaseFldsOnBasisOfBussinessUnit(List<Case> newCaseLst) {

        Map<String, BusinessHours> mapOf_BusinessUnit_To_BusinessHr = new Map<String, BusinessHours>();
        Set<String> setOfCaseBusinessUnit = new Set<String>();

        for(Case csRec : newCaseLst) {
            if(String.isNotBlank(csRec.Business_Unit__c)) {
                if(csRec.Business_Unit__c == 'ABWM'){
                  String bussUnit = 'ABFL'; 
                    if(!setOfCaseBusinessUnit.contains(bussUnit)) {
                        setOfCaseBusinessUnit.add('%' + bussUnit + '%');
                    } 
                }
                else{
                    String bussUnit = csRec.Business_Unit__c; 
                    if(!setOfCaseBusinessUnit.contains(bussUnit)) {
                    setOfCaseBusinessUnit.add('%' + bussUnit + '%');
                    } 
                }
            }
        }

        List<BusinessHours> bhList = [SELECT id, Name FROM BusinessHours WHERE Name Like :setOfCaseBusinessUnit AND IsActive = true WITH SECURITY_ENFORCED];
        
        if(bhList.size() > 0) {

            for(BusinessHours bh : bhList) {
                String bussHrName = bh.Name;
                if(bussHrName.containsIgnoreCase('ABHFL')) {
                    mapOf_BusinessUnit_To_BusinessHr.put('ABHFL', bh);
                }
                else if(bussHrName.containsIgnoreCase('ABFL')) {
                    mapOf_BusinessUnit_To_BusinessHr.put('ABFL', bh);
                }
                else if(bussHrName.containsIgnoreCase('Payments')) {
                    mapOf_BusinessUnit_To_BusinessHr.put('Payments', bh);
                }
                else if(bussHrName.containsIgnoreCase('ABSLIG')) {
                    mapOf_BusinessUnit_To_BusinessHr.put('ABSLIG', bh);
                }
                else if(bussHrName.containsIgnoreCase('ABSLI')) {
                    mapOf_BusinessUnit_To_BusinessHr.put('ABSLI', bh);
                }
                else if(bussHrName.containsIgnoreCase('ABHI')) {
                    mapOf_BusinessUnit_To_BusinessHr.put('ABHI', bh);
                }
            }
        
            for(Case csRec : newCaseLst) {  
                if(String.isNotBlank(csRec.Business_Unit__c)) {
                    String busshrId ='';
                    if(csRec.Business_Unit__c == 'ABWM'){
                         busshrId = mapOf_BusinessUnit_To_BusinessHr.get('ABFL') != null ? mapOf_BusinessUnit_To_BusinessHr.get('ABFL').Id : '';
                    }
                    else{
                         busshrId = mapOf_BusinessUnit_To_BusinessHr.get(csRec.Business_Unit__c) != null ? mapOf_BusinessUnit_To_BusinessHr.get(csRec.Business_Unit__c).Id : null;
                    }
                    csRec.BusinessHoursId = busshrId;
                }
            }
        }
    }

    /****************************************************************************************************************
    * @Function - populateResolutionCommentOnCaseDetail
    * @param newItems oldMap -  list of sobject records. map of trigger.oldMap
    * @return - void .
    * @Description - Updates the resolution comment/remarks field on Case Detail object 
    * when case is being resolved from bulk screen. Copies the value from Resolution Comment field on Case.
    *****************************************************************************************************************/
    public static void populateResolutionCommentOnCaseDetail(List<Case> newItems, Map<Id, Case> oldMap) {
        
        //if not bulk processing, do nothing, return;
        if(!ASF_BulkCaseProcessorUtility.isBulkProcessing){return;}

        List<SObject> recordsToUpdate = new List<SObject>();
        for(Case caseRec : newItems){
            if(caseRec.Stage__c == 'Resolved' && caseRec.Stage__c != oldMap.get(caseRec.Id).Stage__c){
                if(caseRec.ABFL_Case_Detail__c != null){
                    ABFL_Case_Detail__c detRec = new ABFL_Case_Detail__c(Id=caseRec.ABFL_Case_Detail__c);
                    detRec.Resolution_Comments__c = caseRec.Resolution_Comments__c;
                    recordsToUpdate.add(detRec);
                }
                if(caseRec.ABHFL_Case_Detail__c != null){
                    ABHFL_Case_Detail__c detRec = new ABHFL_Case_Detail__c(Id=caseRec.ABHFL_Case_Detail__c);
                    detRec.Resolution_Remarks__c = caseRec.Resolution_Comments__c;
                    recordsToUpdate.add(detRec);
                }
            }
        }
        
        if(!recordsToUpdate.isEmpty()){
            
            update recordsToUpdate;
        }
        
    }
    //This method bypasses the validation rule for System Admin and API profiles
    public static boolean bypassValidation(){
        boolean result = false;
        
        List<Id> bypassProfileId = new List<Id>();
        for(Profile profRec : [select Id, Name from profile where Name IN : ASF_Constants.VALIDATION_BYPASS_PROFILES]){
            bypassProfileId.add(profRec.Id);
        }
        //Bypass owner validations for the sys admin and Integration Profiles
        if(bypassProfileId.contains(UserInfo.getProfileId())){
            return true;
        }
        return result;
    }
}