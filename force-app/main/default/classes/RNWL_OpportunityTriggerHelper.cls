public class RNWL_OpportunityTriggerHelper {
    
    // Wrapper for Schedule Response or Cancel Response 
    public class ResponseWrapper{
        public Integer responseCode;
        Public String responseDesc;
    } 
    
    /****************************************************************************************************************
* @Function - setOpportunityFieldValues
* @param newOppsList -  list of Opportunities from trigger.new.
* @return - void .
* @Description - Invoked from BeforeInsert this method pre-populates fields on Opps from Asset record.
*****************************************************************************************************************/
    /*public static void setOpportunityFieldValues(List<Opportunity> newOppsList){
        
        Set<Id> policyIdSet = new Set<Id>();
        Map<Id, Id> policyAccIdMap = new Map<Id, Id>();
        
        for(Opportunity opp : newOppsList){
            if(!String.isBlank(opp.Policy__c)){
                policyIdSet.add(opp.Policy__c);
            }
        }
        
        for(Asset asst : getPolicies(policyIdSet)){
            policyAccIdMap.put(asst.Id, asst.AccountId);
        }
        
        for(Opportunity opp : newOppsList){
            opp.CloseDate = Date.today() + 60;
            opp.AccountId = policyAccIdMap.get(opp.Policy__c);
            opp.StageName = 'Open'; 
            opp.Name = 'RN-' + opp.Policy_Number__c;            
        }
    }*/
    
    
    /****************************************************************************************************************
* @Function - setOpportunityFieldValues
* @param newItemsOpportunity ,oldItemsOpportunity -  map of Opportunities from trigger.newMap and trigger.oldMap.
* @return - void .
* @Description - Invoked from Before Update this method pre-populates Dialer_Status__c fields on Opps.
*****************************************************************************************************************/
    public static void setBeforeUpdateOppFieldValues(List<Opportunity> newItemsOpportunity, map<Id, Opportunity> oldItemsOpportunity){
        
        for(Opportunity objOpportunity : newItemsOpportunity){           
            Opportunity objOldOpportunity = oldItemsOpportunity.get(objOpportunity.Id); 
            
            try{ 
                if(objOpportunity.Schedule_Request_Response__c != objOldOpportunity.Schedule_Request_Response__c
                   && objOpportunity.Schedule_Request_Response__c != null){
                       
                       ResponseWrapper response = (ResponseWrapper) JSON.deserialize(objOpportunity.Schedule_Request_Response__c, ResponseWrapper.class);             
                       
                       if(response.responseCode == 0) {
                           objOpportunity.Dialer_Status__c = 'Schedule Call Request Successful';
                       } else {
                           objOpportunity.Dialer_Status__c = 'Schedule Call Request Failed';
                       } 
                   }  
            } catch(Exception ex){
                System.debug('Invalid JSON in Response' +ex.getMessage());
                objOpportunity.Dialer_Status__c = 'Schedule Call Request Failed';
            }
            
            try{ 
                if(objOpportunity.Cancel_Call_Response__c != objOldOpportunity.Cancel_Call_Response__c
                   && objOpportunity.Cancel_Call_Response__c != null){
                       
                       ResponseWrapper response = (ResponseWrapper) JSON.deserialize(objOpportunity.Cancel_Call_Response__c, ResponseWrapper.class);             
                       
                       if(response.responseCode == 0) {
                           objOpportunity.Dialer_Status__c = 'Cancel Call Request Successful';
                       } else {
                           objOpportunity.Dialer_Status__c = 'Cancel Call Request Failed';
                       } 
                   } 
                
            } catch(Exception ex){
                System.debug('Invalid JSON in Response' +ex.getMessage());
                objOpportunity.Dialer_Status__c = 'Cancel Call Request Failed';
            }
            
            if(objOpportunity.StageName != objOldOpportunity.StageName && 
               (objOpportunity.StageName == 'Closed Won' || objOpportunity.StageName == 'Closed Lost')) {
                   objOpportunity.Dialer_Status__c = 'Cancel Call Request Submitted';
               }
        } 
    } 
    
    /****************************************************************************************************************
    * @Function - afterUpdateOpp
    * @param newItemsOpportunity ,oldItemsOpportunity -  map of Opportunities from trigger.newMap and trigger.oldMap.
    * @return - void .
    * @Description - Invoked from After Update this method publish event 
    * 				 Updates the field Calling SOurce on Asset and Account when Opps Calling Source Changes
    *****************************************************************************************************************/
    public static void afterUpdateOpp(List<Opportunity> newItemsOpportunity, map<Id, Opportunity> oldItemsOpportunity){
        
        //For Calling Source Update
        Set<Id> oppIdSet = new Set<Id>();
        List<sObject> recordsToUpdate = new List<sObject>();
        
        // FOr PE
        List<ABCL_Integration_Event__e> lstIntegrationEvent = new List<ABCL_Integration_Event__e>();
        
        for(Opportunity objOpportunity : newItemsOpportunity){           
            Opportunity objOldOpportunity = oldItemsOpportunity.get(objOpportunity.Id); 
            
            //for PE
            if((objOpportunity.StageName != objOldOpportunity.StageName && 
                (objOpportunity.StageName == 'Paid')) ||
               (objOpportunity.Dialer_Status__c == 'Cancel Call Request Submitted' && 
                objOldOpportunity.Dialer_Status__c == 'Cancel Call Request Failed')) { 
                    ABCL_Integration_Event__e objIntegration_Event = new ABCL_Integration_Event__e();
                    objIntegration_Event.Business_Unit__c = 'ABHI-RNWL';
                    objIntegration_Event.ObjectApiName__c = 'Opportunity'; 
                    objIntegration_Event.Record_Id__c = objOpportunity.Id;
                    objIntegration_Event.Request__c = '"{ "requestId": " ' + objOpportunity.Name + ' "}"' ; 
                    objIntegration_Event.ServiceName__c = 'UbonaCancelCallService_Renewal';
                    lstIntegrationEvent.add(objIntegration_Event);
            }
            
            //For Calling Source Update
            if(objOpportunity.Calling_Source__c != null &&
              objOpportunity.Calling_Source__c != objOldOpportunity.Calling_Source__c){
              	 oppIdSet.add(objOpportunity.Id);   
            }            
        } 
        //For PE
        if(!lstIntegrationEvent.isEmpty()){
            List<Database.SaveResult> results = EventBus.publish(lstIntegrationEvent);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                    }
                }       
            }
        }
        
        //For Calling Source Update
        if(oppIdSet.size() > 0){ 
            List<Opportunity> oppsChanged = getOpportunitiesById(oppIdSet);
            for(Opportunity opp : oppsChanged){
                if(opp.Calling_Source__c != opp.Policy__r.Calling_Source__c){
                    recordsToUpdate.add(new Asset(Id = opp.Policy__c, Calling_Source__c = opp.Calling_Source__c));
                }
                if(opp.Calling_Source__c != opp.Account.Calling_Source__c){
                    recordsToUpdate.add(new Account(Id = opp.AccountId, Calling_Source__c = opp.Calling_Source__c));
                }
            }
            if(recordsToUpdate.size() > 0){
                update recordsToUpdate;
            }
        }
        
    } 
    /****************************************************************************************************************
    * @Function - tagOppOnDisposition
    * @param newOpps -  list of Opportunities from trigger.new
    * @return - void .
    * @Description - Invoked from After Update, this method updates Renewal_Request field on Disposition for Renewal Category
    *****************************************************************************************************************/
    public static void tagOppOnDisposition(List<Opportunity> newOpps){

        Map<Id, Id> oppToPolicyIdMap = new Map<Id, Id>();
        List<Dispositions__c> updateDispList = new List<Dispositions__c>();

        for(Opportunity opp : newOpps){
            oppToPolicyIdMap.put(opp.Policy__c, opp.Id);
        }

        List<Asset> policiesList = getPolicies(oppToPolicyIdMap.keySet());
        if(policiesList.size() == 0){ return; }

        for(Asset pol : policiesList){
            
            if(pol.Dispositions__r.size() == 0){ return; }
            
            for(Dispositions__c disp : pol.Dispositions__r){
                if(disp.Category__c == 'Renewal' && disp.Renewal_Request__c == null){
                    updateDispList.add(
                        new Dispositions__c(
                            Id = disp.Id, 
                            Renewal_Request__c = oppToPolicyIdMap.get(pol.Id))
                    );
                }
            }
        }

        if(updateDispList.size() > 0){
            update updateDispList;
        }
    }
    
/*****************************************************************************************************************
*                                      Data Getters
*****************************************************************************************************************/
    
    private static List<Asset> getPolicies(Set<Id> policyIdSet){
        return [SELECT 
                Id, AccountId, 
                Calling_Source__c,
                    (SELECT Id, 
                        Category__c,
                        Renewal_Request__c
                    FROM Dispositions__r)
                FROM Asset 
                WHERE Id IN : policyIdSet];
        
    }
    
    private static List<Opportunity> getOpportunitiesById(Set<Id> oppIds){
        return [
            SELECT Id, AccountId,
                Policy__c, 
                Calling_Source__c,
            	Policy__r.Calling_Source__c,
                Account.Calling_Source__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ];
    }
    
}