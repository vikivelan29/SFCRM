public with sharing class ABSLAMC_HoldingsByFolioController {
    
    @AuraEnabled
    public static resultWrapper getSIPResponse(String folioId) {
        
        resultWrapper wrap = new resultWrapper();
        Asset folio = getAsset(folioId);
        string request = '{"folio_id":"'+folio.Folio__c+'"}';  
        System.debug('requestSIP:'+request);
        ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABCL_IntegrationCallout.executeCallout('ABAMC_Get_SIP_Details', request, null);
        if(responseWrapper != null && responseWrapper.statusCode == 200){
            wrap.responseBody = responseWrapper.responseBody;
            wrap.isSuccess = true;
        }else{
            wrap.isSuccess = false;
            wrap.errorMessage = responseWrapper.responseBody;
        }
        System.debug('Wrapper:'+wrap);
        return wrap;
    }
    
    @AuraEnabled
    public static resultWrapper getHoldingsResponse(String folioId) {
        
        resultWrapper wrap = new resultWrapper();
        Asset folio = getAsset(folioId);
        string request = '{"folio_id":"'+folio.Folio__c+'"}';  
        System.debug('requestHolding:'+request);
        ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABCL_IntegrationCallout.executeCallout('ABAMC_Get_Holding_Details', request, null);
        if(responseWrapper != null && responseWrapper.statusCode == 200){
            wrap.responseBody = responseWrapper.responseBody;
            wrap.isSuccess = true;
        }else{
            wrap.isSuccess = false;
            wrap.errorMessage = responseWrapper.responseBody;
        }
        System.debug('Wrapper:'+wrap);
        return wrap;
    }
    
    public static Asset getAsset(string assetId){
        return [Select Id,Folio__c from Asset
                Where id =: assetId
                AND Business_Unit__c =: ABSLAMC_Constants.ABSLAMCBU LIMIT 1];
    }
    
    public class resultWrapper {
        @AuraEnabled public Boolean isSuccess{get;set;}
        @AuraEnabled public String errorMessage{get;set;}
        @AuraEnabled public String responseBody{get;set;}
    }
    
}