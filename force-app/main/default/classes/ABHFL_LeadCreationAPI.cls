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
    public static string sendLead(Id leadId){
        String message; 
        Lead leadObj = [SELECT Id, Company, Email, FirstName, LastName, Employment_Type__c, External_Lead_ID__c, ABHFL_Prospect_Type__c,
                                   MobilePhone, PANNO__c, Preferred_Communication__c, Product__c, Prospect_Type__c,API_Response_Message__c,
                                   RecordType.Name, Requested_Loan_Amount__c, Source_System_API__c, Source_Type__c,Create_Lead_To_CRM_Status__c,
                                   LeadSource, Sourcing_Branch__c, Sub_Source__c, Sub_Variant__c, Variant__c, SPOC_Name__c
                            FROM Lead WHERE Id =: leadId WITH SECURITY_ENFORCED];
            
            If(leadObj != null && checkConditions(leadObj)){
               // Create a PayloadWrapper instance and map the Lead fields
                PayloadWrapper payloadWrp = new PayloadWrapper(leadObj);
                String payload = JSON.serialize(payloadWrp);
                
                system.debug('Payload==='+payload);
                
                ResponseWrapper responseWrapperObj = new ResponseWrapper();
                ABCL_IntegrationCallout.IntegrationResponseWrapper leadCreationWrp = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.SEND_LEAD_TO_CRM,payload,null);
                responseWrapperObj = responseWrapperObj.parse(leadCreationWrp.responseBody);
                if(responseWrapperObj.StatusCode == '200'){
                    leadObj.API_Response_Message__c = responseWrapperObj.Message;
                    leadObj.Create_Lead_To_CRM_Status__c = 'Success';
                    message = 'Send Lead to CRM is Successful';
                }else{
                    message = responseWrapperObj.Message;
                    leadObj.API_Response_Message__c = responseWrapperObj.Message;
                    leadObj.Create_Lead_To_CRM_Status__c = responseWrapperObj.status;
                    throw new AuraHandledException(message);
                }
            }else{
                message = 'Required fields are missing';
                throw new AuraHandledException(message);
            }
            
        return message;
    }
    
    private static boolean checkConditions(Lead leadObj){
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
    }
    
    public class PayloadWrapper {
        public String companyName;
        //public String email;
        public String employmentType;
        public String externalLeadID;
        public String firstName;
        public String lastName;
        public String mobile;
        //public String panNo;
        public String preferredCommunication;
        public String product;
        public String prospectType;
        public Decimal requestedLoanAmount;
        public String sourceSystemAPI;
        public String sourceType;
        public String source;
        public String sourcingBranch;
        public String subSource;
        //public String subVariant;
        //public String variant;
        //public String recordType;
        //public string distributerName;
        public string spocName;
    
        // Constructor to map Lead fields to PayloadWrapper fields
        public PayloadWrapper(Lead leadObj) {
            this.companyName = leadObj.Company;
            //this.email = leadObj.Email;
            this.employmentType = leadObj.Employment_Type__c;
            this.externalLeadID = leadObj.External_Lead_ID__c;
            this.firstName = leadObj.FirstName;
            this.lastName = leadObj.LastName;
            this.mobile = leadObj.MobilePhone;
            //this.panNo = leadObj.PANNO__c;
            this.preferredCommunication = 'SMS,Email';
            this.product = leadObj.Product__c;
            this.prospectType = leadObj.ABHFL_Prospect_Type__c;
            this.requestedLoanAmount = leadObj.Requested_Loan_Amount__c;
            this.sourceSystemAPI = 'SFDC';
            this.sourceType = 'Internal';
            this.source = leadObj.LeadSource;
            this.sourcingBranch = leadObj.Sourcing_Branch__c;
            this.subSource = leadObj.Sub_Source__c;
            //this.subVariant = leadObj.Sub_Variant__c;
            //this.variant = leadObj.Variant__c;
            //this.recordType = leadObj.RecordType.Name;
            //this.distributerName = leadObj.Distributer_Name__c;
            this.spocName = leadObj.SPOC_Name__c;
        }
    }
    
    public class ResponseWrapper{
        public String statusCode;
        public String status;
        public String message;
        
        public ResponseWrapper parse(String json) {
            return (ResponseWrapper) System.JSON.deserialize(json, ResponseWrapper.class);
        }
    }
}