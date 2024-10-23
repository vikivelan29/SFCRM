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
*****************************************************************************************************************/
    public static void afterUpdateOpp(List<Opportunity> newItemsOpportunity, map<Id, Opportunity> oldItemsOpportunity){
        
        List<ABCL_Integration_Event__e> lstIntegrationEvent = new List<ABCL_Integration_Event__e>();
        for(Opportunity objOpportunity : newItemsOpportunity){           
            Opportunity objOldOpportunity = oldItemsOpportunity.get(objOpportunity.Id); 
            
            if((objOpportunity.StageName != objOldOpportunity.StageName && 
                (objOpportunity.StageName == 'Closed Won' || objOpportunity.StageName == 'Closed Lost')) ||
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
        } 
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
        
        
    } 
    
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
                    (SELECT Id, 
                        Category__c,
                        Renewal_Request__c
                    FROM Dispositions__r)
                FROM Asset 
                WHERE Id IN : policyIdSet];
        
    }
    
}