/**
 * @description       : Class for delegating the business logic
 * @author            : Anirudh Raturi
 * @createdDate       : 08-06-2024
 * @last modified on  : 08-06-2024
 * @last modified by  : Anirudh Raturi 
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   08-06-2024   Anirudh Raturi   Initial Version
**/

public without sharing class ABSLIG_CaseDetailTriggerHandler extends ASF_VTriggerHandler {

    public override void beforeUpdate(Map<Id, SObject> newCaseMap, Map<Id, SObject> oldItems) {

        ABSLIG_CaseDetailTriggerHelper absligCsDetTrggrHelper = new ABSLIG_CaseDetailTriggerHelper();
        absligCsDetTrggrHelper.populateFieldsOfABSLIGCaseDetail((Map<Id, ABSLIG_Case_Detail__c>)newCaseMap, (Map<Id, ABSLIG_Case_Detail__c>)oldItems);
    }
}