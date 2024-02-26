/*********************************************************
*Class        :  ABHFL_LeadCreationAPI 
*Author       :  Vishal Gangwar
*Created Date :  25/01/2024
*Last Modified:  
*Description  :  Sending Lead To External Lead Management System
*********************************************************/

public with sharing class ABHFL_LeadCreationAPI {
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - sendLead
    * @param leadId - Lead Id getting from abhfl_SendLeadToCRM Lwc Component.
    * @return - string
    * @description - Invoked from the abhfl_SendLeadToCRM Lwc components to send lead to External Lead management system
    *****************************************************************************************************************/
    @auraEnabled
    public static string sendLead(Id leadId, boolean executingFromTrigger){
        String message; 
        Lead leadObj = [SELECT Id, Company, Email, FirstName, LastName, Employment_Type__c, External_Lead_ID__c, ABHFL_Prospect_Type__c,
                                   MobilePhone, PANNO__c, Preferred_Communication__c, Product__c, Prospect_Type__c,API_Response_Message__c,
                                   RecordType.Name, Requested_Loan_Amount__c, Source_System_API__c, Source_Type__c,Create_Lead_To_CRM_Status__c,
                                   LeadSource, Sourcing_Branch__c, Sub_Source__c, Sub_Variant__c, Variant__c, SPOC_Name__c
                            FROM Lead WHERE Id =: leadId WITH SECURITY_ENFORCED];
            
            If(leadObj != null){
               // Create a PayloadWrapper instance and map the Lead fields
                PayloadWrapper payloadWrp = new PayloadWrapper(leadObj);
                String payload = JSON.serialize(payloadWrp);
                
                system.debug('Payload==='+payload);
                
                ResponseWrapper responseWrapperObj = new ResponseWrapper();
                ABCL_IntegrationCallout.IntegrationResponseWrapper leadCreationWrp = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.SEND_LEAD_TO_CRM,payload,null);
                if(!Test.isRunningTest()){
                    system.debug('leadCreationWrp.responseBody==='+leadCreationWrp.responseBody);
                    responseWrapperObj = responseWrapperObj.parse(leadCreationWrp.responseBody);
                }
                if(responseWrapperObj.Status == '200'){
                    leadObj.API_Response_Message__c = responseWrapperObj.Message;
                    leadObj.Create_Lead_To_CRM_Status__c = 'Success';
                    message = 'Send Lead to CRM is Successful';
                }else{
                    message = responseWrapperObj.Message;
                    leadObj.API_Response_Message__c = responseWrapperObj.Message;
                    leadObj.Create_Lead_To_CRM_Status__c = responseWrapperObj.status;
                    leadObj.API_Error_Code__c = responseWrapperObj.ErrorCode;
                    if(!Test.isRunningTest() && !executingFromTrigger){
                       throw new AuraHandledException(message);
                    }
                }
                
                try{
                    UPDATE leadObj;
                }catch(Exception e){
                    system.debug('Error=='+e.getMessage());
                }
            }
        return message;
    }
    
    @future (callout=true)
    public static void executeSendLeadToCRM(Id leadId){
        sendLead(leadId, true);
    }
    
    /*private static boolean checkConditions(Lead leadObj){
        if(leadObj.Product__c == null || leadObj.ABHFL_Prospect_Type__c == null || leadObj.LeadSource == null || 
           leadObj.LeadSource == null || leadObj.Sub_Source__c == null || leadObj.MobilePhone == null || 
           leadObj.Employment_Type__c == null || leadObj.Sourcing_Branch__c == null || leadObj.Requested_Loan_Amount__c == null){
               return false;
        }
        
        if(leadObj.ABHFL_Prospect_Type__c == 'Individual'){
            if(leadObj.FirstName == null || leadObj.LastName == null){
                return false;
            }
        }
        
        if(leadObj.ABHFL_Prospect_Type__c == 'Non Individual'){
            if(leadObj.Company == null || leadObj.SPOC_Name__c == null){
                return false;
            }
        }
        
        return true;
    }*/
    
    public class PayloadWrapper {
        public String Company_Name;
        public String Email;
        public String Employment_Type;
        public String External_Lead_ID;
        public String First_Name;
        public String Last_Name;
        public String Mobile_Number;
        public String PAN;
        public String Preferred_Communication;
        public String Product;
        public String Prospect_Type;
        public Decimal Requested_Loan_Amount;
        public String Source_System_API;
        public String Source_Type;
        public String Source;
        public String Sourcing_Branch;
        public String SubSource;
        public String Sub_Variant;
        public String Variant;
        public String RecordType;
        //public string distributerName;
        public string SPOC_Name;
    
        // Constructor to map Lead fields to PayloadWrapper fields
        public PayloadWrapper(Lead leadObj) {
            this.Company_Name = leadObj.Company;
            this.Email = leadObj.Email;
            this.Employment_Type = leadObj.Employment_Type__c;
            this.External_Lead_ID = leadObj.External_Lead_ID__c;
            this.Mobile_Number = leadObj.MobilePhone;
            this.PAN = leadObj.PANNO__c;
            this.Preferred_Communication = leadObj.Preferred_Communication__c;
            this.Product = leadObj.Product__c;
            this.Prospect_Type = leadObj.ABHFL_Prospect_Type__c;
            this.Requested_Loan_Amount = leadObj.Requested_Loan_Amount__c;
            this.Source_System_API = ABHFL_Constants.SOURCE_SYSTEM_API;
            this.Source_Type = ABHFL_Constants.SOURCE_TYPE;
            this.Source = leadObj.LeadSource;
            this.Sourcing_Branch = leadObj.Sourcing_Branch__c;
            this.SubSource = leadObj.Sub_Source__c;
            this.Sub_Variant = ABHFL_Constants.SUB_VARIANT;
            this.Variant = ABHFL_Constants.VARIANT;
            this.RecordType = ABHFL_Constants.EXTERNAL_RECORD_TYPE;
           
            //this.distributerName = leadObj.Distributer_Name__c;
            
            if(leadObj.ABHFL_Prospect_Type__c == 'Individual'){
                this.First_Name = leadObj.FirstName;
                this.Last_Name = leadObj.LastName;
            }else{
                this.First_Name = '';
                this.Last_Name = '';
            }

            this.SPOC_Name = leadObj.FirstName + ' ' + leadObj.LastName;
        }
    }

    
    public class ResponseWrapper{
        public String ErrorCode;
        public String Status;
        public String Message;
        
        public ResponseWrapper parse(String json) {
            return (ResponseWrapper) System.JSON.deserialize(json, ResponseWrapper.class);
        }
    }
}