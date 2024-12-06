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
                disp.Priority__c = dispositionPriorityMap.get(disp.Disposition_L1__c+'-'+disp.Disposition_L2__c+'-'+disp.Disposition_L3__c);
                disp.Dashboard_Category__c = dispositionDashboardMap.get(disp.Disposition_L1__c+'-'+disp.Disposition_L2__c+'-'+disp.Disposition_L3__c);
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

            for(Dispositions__c disp : dispositionsListItems){
                    Integer priority = dispositionPriorityMap.get(disp.Disposition_L1__c+'-'+disp.Disposition_L2__c+'-'+disp.Disposition_L3__c);
                    String dashboard = dispositionDashboardMap.get(disp.Disposition_L1__c+'-'+disp.Disposition_L2__c+'-'+disp.Disposition_L3__c);
                    if(disp.Priority__c != priority){
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
    
    private static void setDispositionMapValues(Map<String, Disposition_Priority__mdt> dispositionsMetadata){
        
        for(String name: dispositionsMetadata.keySet()){
            
                if(dispositionsMetadata.get(name).Type__c == 'Priority'){
                    dispositionPriorityMap.put(dispositionsMetadata.get(name).L1__c+'-'+dispositionsMetadata.get(name).L2__c+'-'+dispositionsMetadata.get(name).L3__c,(Integer)dispositionsMetadata.get(name).Priority__c);
                }
                else{
                    dispositionDashboardMap.put(dispositionsMetadata.get(name).L1__c+'-'+dispositionsMetadata.get(name).L2__c+'-'+dispositionsMetadata.get(name).L3__c,dispositionsMetadata.get(name).Dashboard_Category__c);
                }
            }
    }
    
    /****************************************************************************************************************
    * @Function - updateDispositionsOnOpportunity
    * @param newOppsList, oldItems -  list of Dispositons from trigger.newMap and oldmap.
    * @return - void .
    * @Description - after insert and after update to update Best_Disposition__c, Latest_Disposition__c and Disposition_Count__c on opp
    *****************************************************************************************************************/
    // this method signature should be redeployed so commenting around the signature
    public static void updateDispositionsOnOpportunity(List<Dispositions__c> newItems, Map<Id, Dispositions__c> oldItems){
    // this method signature should be redeployed so commenting around the signature
        Set<Id> oppIds = new Set<Id>();

        for(Dispositions__c dis : newItems){
            if(oldItems == null 
               || oldItems.get(dis.Id).Renewal_Request__c != dis.Renewal_Request__c 
               || oldItems.get(dis.Id).Priority__c != dis.Priority__c){
                   if(dis.Renewal_Request__c != null)oppIds.add(dis.Renewal_Request__c);
               }
        }
        
        if(oppIds.size() == 0){return;}
        List<Opportunity> relatedRenewalReq = [SELECT Id, OwnerId ,
                                               (SELECT ID,Priority__c ,Agent_Name__c,Call_Date_Time__c
                                                FROM Dispositions__r ORDER BY CreatedDate DESC)
                                               FROM Opportunity WHERE ID IN:oppIds ];
        
        for(Opportunity opp : relatedRenewalReq){
            opp.Latest_Disposition__c = opp.Dispositions__r[0].Id;
            Integer priority;
            DateTime callDateTime;
            for(Dispositions__c disp : opp.Dispositions__r){
                if(disp.Priority__c != null 
                   && (priority == null || 
                       Integer.valueOf(disp.Priority__c) < priority || 
                       (callDateTime != null && Integer.valueOf(disp.Priority__c) ==  priority && disp.Call_Date_Time__c >  callDateTime))){
                           
                           callDateTime = disp.Call_Date_Time__c;
                           priority = Integer.valueOf(disp.Priority__c);
                           
                           opp.Best_Disposition__c = disp.Id;
                           if(disp.Agent_Name__c != null && opp.OwnerId != disp.Agent_Name__c){
                               opp.OwnerId = disp.Agent_Name__c;
                           }
                       }
            }
            // this line should be redeployed so commenting around the signature
            //Disposition Count Update on Opp
            opp.Disposition_Count__c = opp.Dispositions__r.size();
            // this line should be redeployed so commenting around the signature
        }       
        update relatedRenewalReq;
    }
}