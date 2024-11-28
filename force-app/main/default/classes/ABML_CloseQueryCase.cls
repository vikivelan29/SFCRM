/**
* @description       : ABML Close Query Case
* @author            : saravpreet.arora@in.ey.com
* @group             : 
* @last modified on  : 
* @last modified by  : 
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   22/11/2024   Saravpreet Arora             Initial Version
**/
public with sharing class ABML_CloseQueryCase {
    
    public void prepopulateCaseFlds(List<Case> newItems) {
        for(Case csRec : newItems) {
            if(csRec.Business_Unit__c == 'ABML' && csRec.Nature__c == 'Query' && csRec.Channel__c == 'Inbound Call'){
                csRec.Stage__c = 'Resolved';
                csRec.Status = 'Resolved';
            }
            
        }
    }
}