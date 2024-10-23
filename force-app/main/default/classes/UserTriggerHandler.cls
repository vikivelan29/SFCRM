/*********************************************************
 *Class        :  UserTriggerHandler
 *Author       :  Udit Singhal
 *Created Date :  10/10/2024
 *Description  :  Trigger Handler for User
 *********************************************************/
public class UserTriggerHandler extends ASF_VTriggerHandler{
    public static Boolean TriggerDisabled = false;
    public override void BeforeInsert(List<SObject> newItems){
        ABSLAMC_IDAMHelperClass.populateOldEmail((List<User>)newItems);
    }

    public override void AfterInsert(Map<Id, SObject> newItems){
        ABSLAMC_IDAMHelperClass.handleLOBChanges((Map<Id, User>)newItems, null);
    }

    public override void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        if (!TriggerDisabled){
            //Call helper class method to evaludate if SLA_Target field needs to be updated
            ABSLAMC_IDAMHelperClass.evaluateSLATargetUpdates((Map<Id, User>)newItems, (Map<Id, User>)oldItems);
            ABSLAMC_IDAMHelperClass.handleLOBChanges((Map<Id, User>)newItems, (Map<Id, User>)oldItems);
        }
    }

}