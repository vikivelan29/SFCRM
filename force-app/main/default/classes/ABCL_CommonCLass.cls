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
        populateCreatedDateRange(newCaseList);
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
                system.debug('line no 58 BH-->'+bh);
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
                else if(bussHrName.containsIgnoreCase('ABSLAMC')){
                    mapOf_BusinessUnit_To_BusinessHr.put('ABSLAMC', bh);
                }
                else if(bussHrName.containsIgnoreCase('ABHI')) {
                    mapOf_BusinessUnit_To_BusinessHr.put('ABHI', bh);
                }else if(bussHrName.containsIgnoreCase('Wellness')) { //PR1030924-213 : Zahed added wellness condition
                    mapOf_BusinessUnit_To_BusinessHr.put('Wellness', bh);
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
        Map<Id,SObject> recordupdateABFLcaseDetail = new Map<Id,SObject>();    // added by vikas
        for(Case caseRec : newItems){
            if(caseRec.Stage__c == 'Resolved' && caseRec.Stage__c != oldMap.get(caseRec.Id).Stage__c){
                if(caseRec.ABFL_Case_Detail__c != null){
                    ABFL_Case_Detail__c detRec = new ABFL_Case_Detail__c(Id=caseRec.ABFL_Case_Detail__c);
                    detRec.Resolution_Comments__c = caseRec.Resolution_Comments__c;
                    //recordmap.put(detRec.Id,detRec);      
                    recordupdateABFLcaseDetail.put(caseRec.ABFL_Case_Detail__c,detRec);          //added by vikas
                    recordsToUpdate.add(detRec);
                }
                if(caseRec.ABHFL_Case_Detail__c != null){
                    ABHFL_Case_Detail__c detRec = new ABHFL_Case_Detail__c(Id=caseRec.ABHFL_Case_Detail__c);
                    detRec.Resolution_Remarks__c = caseRec.Resolution_Comments__c;
                    recordsToUpdate.add(detRec);
                }
            }
            recordsToUpdate.addAll(recordupdateABFLcaseDetail.values());        // added by vikas
        }
        
        if(!recordsToUpdate.isEmpty()){
            
            // update recordsToUpdate;
            Database.update(recordsToUpdate, false);               // added by vikas
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

    /**
	* @Function - populateCreatedDateRange
	* @param newItems -  map of Case from trigger.new.
	* @description - Invoked from BeforeInsert method, this method pre-populates fields on Case.
	**/
    public void populateCreatedDateRange(List<Case> newItems) {

        Datetime currentDatetime = System.now();
        Integer currentHour = currentDatetime.hour();
        Integer currentMinute = currentDatetime.minute();
        Integer timeInMinutes =  currentHour*60 + currentMinute;
        String businessUnitCheck = System.label.Business_Unit_Check_For_SLA_Override ?? '';

        for(Case caseRec : newItems){
            String caseBusinessUnit = caseRec?.Business_Unit__c ?? '';

            if(businessUnitCheck.containsIgnoreCase(caseBusinessUnit)) {
                caseRec.Created_Date_Range__c = calculateSlaOverwriteIdentifier(timeInMinutes);    
            }
        }
    }

    /**
	* @Function - populateCreatedDateRange
	* @param calculateMinutes -  Time in minutes.
	* @return - String
	* @description - Method to calculate the SLA Overwrite Identifier
	**/
    @SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
    public String calculateSlaOverwriteIdentifier(Integer calculateMinutes) {
        
        String slaOverwriteIdentifier = '';
        if(calculateMinutes > 0 && calculateMinutes <= 900) {
            if(calculateMinutes <= 900) {
                slaOverwriteIdentifier = '1';
            }
            else if(calculateMinutes > 900 && calculateMinutes <= 960) {
                slaOverwriteIdentifier = '2';
            }
            else if(calculateMinutes > 960 && calculateMinutes <= 1020) {
                slaOverwriteIdentifier = '3';
            }
            else if(calculateMinutes > 1020 && calculateMinutes <= 1080) {
                slaOverwriteIdentifier = '4';
            }
            else if(calculateMinutes > 1080 && calculateMinutes <= 1140) {
                slaOverwriteIdentifier = '5';
            }
            else if(calculateMinutes > 1140 && calculateMinutes <= 1200) {
                slaOverwriteIdentifier = '6';
            }
            else if(calculateMinutes > 1200 && calculateMinutes <= 1260) {
                slaOverwriteIdentifier = '7';
            }
            else if(calculateMinutes > 1260 && calculateMinutes <= 1320) {
                slaOverwriteIdentifier = '8';
            }
            
            else if(calculateMinutes > 1320 && calculateMinutes <= 1440) {
                slaOverwriteIdentifier = '1';
            }            
        }
        return slaOverwriteIdentifier;
    }
}