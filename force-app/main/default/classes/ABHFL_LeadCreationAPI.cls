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
        try{
            Lead leadObj = [SELECT Id, Company, Email, FirstName, LastName, Employment_Type__c, //External_Lead_ID__c, 
                                   MobilePhone, PANNO__c, Preferred_Communication__c, Product__c, Prospect_Type__c,
                                   RecordType.Name, Requested_Loan_Amount__c, Source_System_API__c, Source_Type__c,
                                   LeadSource, Sourcing_Branch__c, Sub_Source__c, Sub_Variant__c, Variant__c
                            FROM Lead WHERE Id =: leadId WITH SECURITY_ENFORCED];
            
            If(leadObj != null){
                // Create a PayloadWrapper instance and map the Lead fields
                PayloadWrapper payloadWrp = new PayloadWrapper(leadObj);
                String payload = JSON.serialize(payloadWrp);
                
                ResponseWrapper responseWrapperObj = new ResponseWrapper();
                ABCL_IntegrationCallout.IntegrationResponseWrapper leadCreationWrp = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.SEND_LEAD_TO_CRM,payload,null);
                responseWrapperObj = responseWrapperObj.parse(leadCreationWrp.responseBody);
                if(responseWrapperObj.StatusCode == '200'){
                    message = 'Send Lead to CRM is Successful';
                }else{
                    message = responseWrapperObj.Message;
                }
            }
        }catch(Exception e){
            message = 'Send Lead to CRM is Failed';
        }
        return message;
    }
    
    public class PayloadWrapper {
        public String companyName;
        public String email;
        public String employmentType;
        public String externalLeadID;
        public String firstName;
        public String lastName;
        public String mobile;
        public String panNo;
        public String preferredCommunication;
        public String product;
        public String prospectType;
        public Decimal requestedLoanAmount;
        public String sourceSystemAPI;
        public String sourceType;
        public String source;
        public String sourcingBranch;
        public String subSource;
        public String subVariant;
        public String variant;
        public String recordType;
        public string distributerName;
    
        // Constructor to map Lead fields to PayloadWrapper fields
        public PayloadWrapper(Lead leadObj) {
            this.companyName = leadObj.Company;
            this.email = leadObj.Email;
            this.employmentType = leadObj.Employment_Type__c;
            //this.externalLeadID = leadObj.External_Lead_ID__c;
            this.firstName = leadObj.FirstName;
            this.lastName = leadObj.LastName;
            this.mobile = leadObj.MobilePhone;
            this.panNo = leadObj.PANNO__c;
            this.preferredCommunication = leadObj.Preferred_Communication__c;
            this.product = leadObj.Product__c;
            this.prospectType = leadObj.Prospect_Type__c;
            this.requestedLoanAmount = leadObj.Requested_Loan_Amount__c;
            this.sourceSystemAPI = leadObj.Source_System_API__c;
            this.sourceType = leadObj.Source_Type__c;
            this.source = leadObj.LeadSource;
            this.sourcingBranch = leadObj.Sourcing_Branch__c;
            this.subSource = leadObj.Sub_Source__c;
            this.subVariant = leadObj.Sub_Variant__c;
            this.variant = leadObj.Variant__c;
            this.recordType = leadObj.RecordType.Name;
            if(leadObj.Sub_Source__c != null && (leadObj.Sub_Source__c == 'RP' || leadObj.Sub_Source__c == 'Corp RP' 
                                             || leadObj.Sub_Source__c == 'DSA' || leadObj.Sub_Source__c == 'Corp DSA')){
                this.distributerName = leadObj.Distributer_Name__c;
            }
        }
    }
    
    public class ResponseWrapper{
        public String statusCode;
        public String message;
        
        public ResponseWrapper parse(String json) {
            return (ResponseWrapper) System.JSON.deserialize(json, ResponseWrapper.class);
        }
    }
}