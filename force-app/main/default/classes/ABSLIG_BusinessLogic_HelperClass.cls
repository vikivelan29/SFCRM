/*********************************************************
*Class        :  ABSLIG_BusinessLogic_HelperClass
*Author       :  Anirudh Raturi
*Created Date :  12/07/2024
*Description  :  ABSLIG Business Logic class
*********************************************************/

@SuppressWarnings('PMD.ApexDoc')
public with sharing class ABSLIG_BusinessLogic_HelperClass {
    
    /****************************************************************************************************************
    * @Function - prePopulateFields
    * @param - newLeadList
    * @return - void.
    * @Description - Populating Fields
    ***********************************************************/
    public void prePopulateFields(List<Lead> newLeadList) {
        
        for(Lead ld : newLeadList) {
            if(ld.Business_Unit__c == 'ABSLIG') {
                ld.lastName = ld.company;
            }
        }
    }
}