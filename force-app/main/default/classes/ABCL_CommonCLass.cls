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
                String bussUnit = csRec.Business_Unit__c; 
                if(!setOfCaseBusinessUnit.contains(bussUnit)) {
                    setOfCaseBusinessUnit.add('%' + bussUnit + '%');
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
            }
        
            for(Case csRec : newCaseLst) {  
                if(String.isNotBlank(csRec.Business_Unit__c)) {
                    String busshrId = mapOf_BusinessUnit_To_BusinessHr.get(csRec.Business_Unit__c) != null ? mapOf_BusinessUnit_To_BusinessHr.get(csRec.Business_Unit__c).Id : '';
                    csRec.BusinessHoursId = busshrId;
                }
            }
        }
    }
}