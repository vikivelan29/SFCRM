public class RNWL_DispositionsTriggerHelper {
      
 public static Map<String,Integer> dispositionPriorityMap = new Map<String,Integer>();
 public static Map<String,String> dispositionDashboardMap = new Map<String,String>();
    
/****************************************************************************************************************
* @Function - setBeforeInsertDispositionsPriorityFieldValue
* @param newOppsList -  list of Dispositons from trigger.new.
* @return - void .
* @Description - Invoked from BeforeInsert this method pre-populates priority field on Dispositions from Dispositions Priority Metadata.
*****************************************************************************************************************/
    public static void setBeforeInsertDispositionsPriorityFieldValue(List<Dispositions__c> newDispositionsitems){
        
        
        Map<String, Disposition_Priority__mdt > dispositionsMetadata = Disposition_Priority__mdt.getAll();
        
        setDispositionMapValues(dispositionsMetadata);
        
        for(Dispositions__c disp :newDispositionsitems){
			for(String name: dispositionsPriorityMap.keySet()){
                String L1= dispositionsPriorityMap.get(name).L1__c;
                String L2= dispositionsPriorityMap.get(name).L2__c;
                String L3= dispositionsPriorityMap.get(name).L3__c;
                String L4= dispositionsPriorityMap.get(name).L4__c;
				String L5= dispositionsPriorityMap.get(name).L5__c;
				String L6= dispositionsPriorityMap.get(name).L6__c;
				String L7= dispositionsPriorityMap.get(name).L7__c;                
                String type = dispositionsPriorityMap.get(name).Type__c;
                If(L1 == disp.Disposition_L1__c && L2 == disp.Disposition_L2__c && L3 == disp.Disposition_L3__c && type == 'Priority'){
                    disp.Priority__c = dispositionsPriorityMap.get(name).Priority__c;
                } 
                If(L1 == disp.Disposition_L1__c && L2 == disp.Disposition_L2__c && L3 == disp.Disposition_L3__c && 
                   L4 == disp.Disposition_L4__c  && L5 == disp.Disposition_L5__c && L6 == disp.Disposition_L6__c && 
                   L7 == disp.Disposition_L7__c && type == 'Dashboard'){
                    disp.Dashboard_Category__c = dispositionsPriorityMap.get(name).Dashboard_Category__c;
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
         Map<String, Disposition_Priority__mdt > dispositionsMetadata = Disposition_Priority__mdt.getAll();
            
         setDispositionMapValues(dispositionsMetadata);
            
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
                String type = dispositionsPriorityMap.get(name).Type__c;
                Integer priority = (Integer) dispositionsPriorityMap.get(name).Priority__c;
                If(L1 == disItem.Disposition_L1__c && L2 == disItem.Disposition_L2__c && L3 == disItem.Disposition_L3__c && type == 'Priority'){
                    if(disItem.Priority__c != priority){
                        Dispositions__c dispObj = new Dispositions__c();
                        dispObj.Id = disp.Id;
                        dispObj.Priority__c = priority;
                        dispObj.Dashboard_Category__c = dashboard;
                        dispositionsItemsToUpdate.add(dispObj);
                    }  
            }
            if(!dispositionsItemsToUpdate.isEmpty()){
                Database.update(dispositionsItemsToUpdate);
            }
        }

/****************************************************************************************************************
* @Function - setRenewalRequestOnDisposition
* @param newOppsList -  list of Dispositons from trigger.newMap.
* @return - void .
* @Description - BeforeInsert this method populates opp field on Dispositions using the opp related to the policy on it
*****************************************************************************************************************/
    public static void setRenewalRequestOnDisposition(List<Dispositions__c> dispositions){

        Set<Id> policyIds = new Set<Id>();
        Map<Id, Id> polToOppMap = new Map<Id, Id>();

        for(Dispositions__c disp : dispositions){
            if(disp.Category__c == 'Renewal' && disp.Policy_Number__c != null){
                policyIds.add(disp.Policy_Number__c);
            }
        }

        if(policyIds.size() == 0){ return; }

        for(Opportunity opp : [SELECT Id, Policy__c FROM Opportunity WHERE Policy__c IN : policyIds]){
            polToOppMap.put(opp.Policy__c, opp.Id);
        }

        for(Dispositions__c disp : dispositions){
                disp.Renewal_Request__c = polToOppMap.get(disp.Policy_Number__c);
        }
    }

    public static void updateDispositionsOnOpportunity(Map<Id, Dispositions__c> newItems, Map<Id, Dispositions__c> oldItems){
        Set<Id> oppIds = new Set<Id>();

        try{
            for(Dispositions__c dis : newItems.values()){
                if(oldItems == null 
                || oldItems.get(dis.Id).Renewal_Request__c != dis.Renewal_Request__c 
                || oldItems.get(dis.Id).Priority__c != dis.Priority__c){
                    if(dis.Renewal_Request__c != null)oppIds.add(dis.Renewal_Request__c);
                }
            }
    
            if(oppIds.size() > 0){
                List<Opportunity> relatedRenewalReq = [SELECT Id, 
                                                            (SELECT ID,Priority__c 
                                                            FROM Dispositions__r ORDER BY CreatedDate DESC)
                                                       FROM Opportunity WHERE ID IN:oppIds ];
                
                for(Opportunity opp : relatedRenewalReq){
                    opp.Latest_Disposition__c = opp.Dispositions__r[0].Id;
    
                    Integer priority;
                    for(Dispositions__c disp : opp.Dispositions__r){
                        if(disp.Priority__c != null && (priority == null || disp.Priority__c < priority)){
                            opp.Best_Disposition__c = disp.Id;
                        }
                    }
                }       
                
                update relatedRenewalReq;
            }
        }catch(Exception e){
            System.debug(e.getMessage());
        }
    }
}