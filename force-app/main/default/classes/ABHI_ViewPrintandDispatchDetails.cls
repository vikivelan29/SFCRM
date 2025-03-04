/***************************************
*Class        :  ABHI_ViewPrintandDispatchDetails
*Author       :  Kuldeep Mishra
*Created Date :  05/09/2024
*Last Modified:  05/09/2024
*@description :  This class used as a outBound API call and a controller for abhi_ViewPrintandDispatchDetails component.
***************************************/
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class ABHI_ViewPrintandDispatchDetails {
    
     /**********
     Method Name - GetViewPrintDetails
     @description :  Method returns IntegrationResponse, when assetId is passed on the Asset page.
     ***********/
    @SuppressWarnings('PMD.MethodNamingConventions')
    @AuraEnabled
    public static IntegrationResponseWrapper GetViewPrintDetails(String assetId){ 

        //Boolean hasError = false;
        String customerId;
       Map<String,String> urlParam = new Map<String,String>();
        
        try{
            string integrationName = 'ABHI_ViewPrintandDispatchDetails';
            String policyNumber = '';
            Asset assets = [SELECT Policy_No__c,AccountId from Asset where Id=: assetId WITH SYSTEM_MODE];
        if (assets!= null && assets.Policy_No__c != null){
                policyNumber = assets.Policy_No__c;
                customerId = assets.AccountId;
                System.debug('Policy Number retrieved from Asset: ' + policyNumber);
        }
            ABCL_IntegrationCallout.accountId = customerId;
            urlParam.put('policyNumber',policyNumber);
            
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,null, urlParam);
        system.debug('integrationResp>>' +integrationResp);
        IntegrationResponseWrapper deserializedIntResponse = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
                 return deserializedIntResponse;
        }catch(Exception e){
         throw new AuraHandledException('Error : '+e.getMessage());
        } 
    }
    
    
    //Response Wrapper class
      /**********
     @Class - IntegrationResponseWrapper
     @description :  Request wrapper
     ***********/
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.VariableNamingConventions')
    public class IntegrationResponseWrapper{
        
      @AuraEnabled 
      public vendorPrintWrapper vendorPrintDispatchDetails;
      @AuraEnabled 
      public responseWrapper response; 
    }
    
    /**********
     @Class - IntegrationResponseWrapper
     @description :  Response Wrapper class
     ***********/
       @SuppressWarnings('PMD.ExcessivePublicCount,PMD.ClassNamingConventions,PMD.TooManyFields')
    public class vendorPrintWrapper{
        @AuraEnabled 
        public String flag;
        @AuraEnabled 
        public String productCode;
        @AuraEnabled 
        public String productName;
        @AuraEnabled 
        public String userCode;
        @AuraEnabled 
        public String policyBranch;
        @AuraEnabled 
        public String policyTermUnit;
        @AuraEnabled 
        public String policyInceptionDate;
        @AuraEnabled 
        public String premiumDepositMode;
        @AuraEnabled 
        public String policyStatus;
        @AuraEnabled 
        public String premiumFrequency ;
        @AuraEnabled 
        public String proposalNumber;
        @AuraEnabled 
        public String policyNumber;
        @AuraEnabled 
        public String policyExpiryDate;
        @AuraEnabled 
        public String policyTerm;
        @AuraEnabled 
        public String baseCurrencyRate;
        @AuraEnabled 
        public String baseCurrency;
        @AuraEnabled 
        public String premiumCurrencyRate;
        @AuraEnabled 
        public String premiumCurrency;
        @AuraEnabled 
        public String entityType;
        @AuraEnabled 
        public String suppressFlag;
        @AuraEnabled 
        public List<basicdetailAttributeList> basicdetailAttribute;    
        
    }
    /**********
     @Class - IntegrationResponseWrapper
     @description :  Response Wrapper class
     ***********/
       @SuppressWarnings('PMD.ClassNamingConventions')
    public class basicdetailAttributeList{
        @AuraEnabled 
        public String name;
        @AuraEnabled 
        public String value;   
    }
    /**********
     @Class - IntegrationResponseWrapper
     @description :  Response Wrapper class
     ***********/
       @SuppressWarnings('PMD.ClassNamingConventions')
    public class responseWrapper{
         @AuraEnabled 
        public String responseCode;
        @AuraEnabled 
        public String responseMessage;
        @AuraEnabled 
        public List<messageWrapper> messages;  
    }
    /**********
     @Class - IntegrationResponseWrapper
     @description :  Response Wrapper class
     ***********/
       @SuppressWarnings('PMD.ClassNamingConventions')
    public class messageWrapper{
        @AuraEnabled 
        public String messageCode;
        @AuraEnabled 
        public String messageType;
        @AuraEnabled 
        public String messageDescription;
    }
    
    
    
    
    }