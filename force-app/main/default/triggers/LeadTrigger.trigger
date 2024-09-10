/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 08-16-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   08-16-2024   rsinghnagar@salesforce.com   Initial Version
**/
trigger LeadTrigger on Lead (before insert, after insert, before update) {
    if(FeatureManagement.checkPermission('By_Pass_Trigger')){
        return;
    }

    TriggerDispatcher.Run(new LeadTriggerHandler());
}