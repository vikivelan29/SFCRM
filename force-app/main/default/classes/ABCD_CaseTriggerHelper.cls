/**
* @description       : 
* @author            : Salesforce
* @group             : 
* @last modified on  : 09-12-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   04-24-2024   Salesforce   Initial Version
**/
public class ABCD_CaseTriggerHelper {

    public static void populateCaseBusinessHrs(List<Case> newCase, Map<Id, Case> oldCase) {
		List<Case> caseToRecalculateBusinessHrs = new List<Case>();
        for(Case caseRec : newCase){
            if(caseRec.Business_Unit__c != oldCase.get(caseRec.Id).Business_Unit__c){
                caseToRecalculateBusinessHrs.add(caseRec);
            }  
        }
        ABCL_CommonCLass commonCLssObj = new ABCL_CommonCLass();
        commonCLssObj.prepopulateCaseFldsOnBasisOfBussinessUnit(caseToRecalculateBusinessHrs);
    } 
}