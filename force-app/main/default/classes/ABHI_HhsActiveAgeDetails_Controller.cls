/**************
*Class        :  ABHI_HhsActiveAgeDetails_Controller
*Author       :  Kuldeep Mishra
*Created Date :  12/08/2024
*Last Modified:  15/08/2024
*@description  :  This class is used as controller for the abhi_HHS_Active Component and for calling ActiveHealthdetails API
***************/
@SuppressWarnings('PMD.FieldNamingConventions,PMD.VariableNamingConventions,PMD.ExcessivePublicCount')
public with sharing class ABHI_HhsActiveAgeDetails_Controller {
    
     /**********
     @Method Name - GetHhsActiveAge
     @description :  Method returns IntegrationResponse, when customerId is passed on the Customer page.
     ***********/
   @SuppressWarnings('PMD.MethodNamingConventions')    
   @AuraEnabled
    public static IntegrationResponseWrapper GetHhsActiveAge(string customerId) {
    try{
        String integrationName = 'ABHI_HHS_ActiveAge_Details';
        //String activAge = '1187714';
        ABCL_IntegrationCallout.accountId = customerId;
        Account acc = [SELECT id, name, Client_Code__c from Account where Id =: customerId WITH SYSTEM_MODE];
        Map<String, String> urlParams = new Map<String, String>();
        urlParams.put('customerId', acc.Client_Code__c);
        
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,'',urlParams);
        IntegrationResponseWrapper deserializedIntResp = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
        return deserializedIntResp;
           
        } catch (Exception e) {
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    
    // wrapper class for Integration Response
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.ApexDoc,PMD.VariableNamingConventions')
    public class IntegrationResponseWrapper {
        
       @AuraEnabled public HHSDetailsWrapper HHSDetails;     
       //@AuraEnabled public infoWrapper info;
       @AuraEnabled public activeAgeWrapper activeAge;
       @AuraEnabled public String StatusCode;	
	   @AuraEnabled public String Message;
                public IntegrationResponseWrapper(String statusCode, String responseBody){
            this.StatusCode = statusCode;
            this.Message = responseBody;
        }
        
    }
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.ApexDoc,PMD.VariableNamingConventions')
    public class HHSDetailsWrapper {
       @AuraEnabled public String operationStatus;
       @AuraEnabled public List<serviceMessagesWrapper> serviceMessages;
        @AuraEnabled public responseMapWrapper responseMap;
    }
    
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.ApexDoc,PMD.VariableNamingConventions')
    public class serviceMessagesWrapper{
        
        @AuraEnabled public String systemCode;
        @AuraEnabled public String businessCode;
        @AuraEnabled public String businessDesc;
        @AuraEnabled public String serviceMessageType;
        @AuraEnabled public String messageTime;
       
    }
    
     @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.ApexDoc,PMD.VariableNamingConventions')
    public class responseMapWrapper{
        @AuraEnabled public resultsListWrapper resultsList;
       
        
    }
    
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.ApexDoc,PMD.VariableNamingConventions')
    public class resultsListWrapper {
        @AuraEnabled public String gender;
        @AuraEnabled public Integer totalFsScore;
        @AuraEnabled public String startDate;
        @AuraEnabled public String expiryDate;
        @AuraEnabled public String scoreDate;
        @AuraEnabled public String tierLevelName;
        @AuraEnabled public String customerNumber;
        @AuraEnabled public List<activitiesWrapper> activities;
        
    }
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.ApexDoc,PMD.VariableNamingConventions')  
    public class activitiesWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String code;
        @AuraEnabled public String value;
        @AuraEnabled public Integer score;
        @AuraEnabled public String effFromDate;
        @AuraEnabled public String effToDate;
        @AuraEnabled public List<attributesWrapper> attributes;
        
    }
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.ApexDoc,PMD.VariableNamingConventions')
    public class attributesWrapper{
        @AuraEnabled public String attributeCode;
        @AuraEnabled public String attributeValue;

    }
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.ApexDoc,PMD.VariableNamingConventions')
    public class infoWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public Integer code;
        @AuraEnabled public String value;
        @AuraEnabled public String score; 
    }
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.ApexDoc,PMD.VariableNamingConventions')
    public class activeAgeWrapper{
        @AuraEnabled public Integer CustomerNo;
        @AuraEnabled public Integer ActualAge;
        @AuraEnabled public Integer MultiplyAge;
        @AuraEnabled public double HeartAge;
        @AuraEnabled public String CalculationDate; 
    }

}