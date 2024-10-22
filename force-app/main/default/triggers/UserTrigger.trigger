/**
 * @description       : User Trigger
 * @author            : Udit Singhal
 * @group             : 
 * @last modified on  : 10-10-2024
 * @last modified by  : Udit Singhal
 * Modifications Log
 * Ver   Date         Author                 Modification
 * 1.0   10-10-2024   Udit Singhal           Initial Version
**/
trigger UserTrigger on User (before insert, after insert, after update) {
    if(FeatureManagement.checkPermission('By_Pass_Trigger')){
        return;
    }

    TriggerDispatcher.Run(new UserTriggerHandler());
}