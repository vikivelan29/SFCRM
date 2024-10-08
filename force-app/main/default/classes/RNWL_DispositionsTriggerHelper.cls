public class RNWL_DispositionsTriggerHelper {
    
/****************************************************************************************************************
* @Function - setBeforeInsertDispositionsPriorityFieldValue
* @param newOppsList -  list of Dispositons from trigger.new.
* @return - void .
* @Description - Invoked from BeforeInsert this method pre-populates priority field on Dispositions from Dispositions Priority Metadata.
*****************************************************************************************************************/
    public static void setBeforeInsertDispositionsPriorityFieldValue(List<Dispositions__c> newDispositionsitems){
        
        
        Map<String, Disposition_Priority__mdt > dispositionsPriorityMap = Disposition_Priority__mdt.getAll();
        for(Dispositions__c disp :newDispositionsitems){
			for(String name: dispositionsPriorityMap.keySet()){
                String L1= dispositionsPriorityMap.get(name).L1__c;
                String L2= dispositionsPriorityMap.get(name).L2__c;
                String L3= dispositionsPriorityMap.get(name).L3__c;
                If(L1 == disp.Disposition_L1__c && L2 == disp.Disposition_L2__c && L3 == disp.Disposition_L3__c){
                    disp.Priority__c = dispositionsPriorityMap.get(name).Priority__c;
                }
		    }
        }
        
    }
  /****************************************************************************************************************
* @Function - setAfterInsertDispositionsPriorityFieldValue
* @param newOppsList -  list of Dispositons from trigger.newMap.
* @return - void .
* @Description - Invoked from AfterInsert this method populates priority field on Dispositions from Dispositions Priority Metadata.
*****************************************************************************************************************/
        public static void setAfterInsertDispositionsPriorityFieldValue(List<Dispositions__c> newDispositionsitems){
         Set<Id> oppIdSet = new Set<Id>();
         List<Dispositions__c> dispositionsItemsToUpdate = new List<Dispositions__c>();
         Map<String, Disposition_Priority__mdt > dispositionsPriorityMap = Disposition_Priority__mdt.getAll();

         for(Dispositions__c disp: newDispositionsitems){
             if(!String.isBlank(disp.Renewal_Request__c)){
              oppIdSet.add(disp.Renewal_Request__c); 
             }
         }
         List<Dispositions__c> dispositionsListItems = [Select Id,Name,Priority__c ,Disposition_L1__c ,Disposition_L2__c ,Disposition_L3__c,Renewal_Request__c from Dispositions__c where Renewal_Request__c IN : oppIdSet];

            for(Dispositions__c disItem : dispositionsListItems){
			for(String name: dispositionsPriorityMap.keySet()){
                String L1= dispositionsPriorityMap.get(name).L1__c;
                String L2= dispositionsPriorityMap.get(name).L2__c;
                String L3= dispositionsPriorityMap.get(name).L3__c;
                Integer priority = (Integer) dispositionsPriorityMap.get(name).Priority__c;
                If(L1 == disItem.Disposition_L1__c && L2 == disItem.Disposition_L2__c && L3 == disItem.Disposition_L3__c){
                    if(disItem.Priority__c != priority){
                        Dispositions__c dispObj = new Dispositions__c();
                        dispObj.Id = disItem.Id;
                        dispObj.Priority__c = priority;
                        dispositionsItemsToUpdate.add(dispObj);
                        break;
                    }
                }
		    }   
            }
            if(!dispositionsItemsToUpdate.isEmpty()){
                Database.update(dispositionsItemsToUpdate);
            }
        }
}