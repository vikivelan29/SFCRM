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
        Lead leadObj = new Lead();

        try{
            leadObj = [SELECT Id, Company, Email, FirstName, LastName, Employment_Type__c, ABHFL_Prospect_Type__c, External_Lead_ID__c,
                                    MobilePhone, PANNO__c, Product__c, Prospect_Type__c,API_Response_Message__c, Preferred_Communication__c,
                                    RecordType.Name, Requested_Loan_Amount__c, Source_System_API__c, Source_Type__c,Create_Lead_To_CRM_Status__c,
                                    LeadSource, Sourcing_Branch__c, Sub_Source__c, Sub_Variant__c, Variant__c, SPOC_Name__c,Lead_Stage__c,Source_Code__c, Campaign_Name__c, State__c , ABHFL_Employee_Number_Owner__c, Existing_Customer__c, Is_Property_Identified__c, Distributor_Code_Text__c, Country_Code__c, LAT__c, LOG__c, Street__c, GeocodeAccuracy__c, Property_Address_City__c, Property_Address_CountryCode__c, Property_Address_PostalCode__c, Property_Address_StateCode__c
                                FROM Lead WHERE Id =: leadId AND Business_Unit__c = 'ABHFL'];
        }catch(Exception e){
        }
        If(leadObj != null && leadObj.API_Response_Message__c != 'Created Lead Successfully'){
            PayloadWrapper payloadWrp = new PayloadWrapper(leadObj);
            String payload = JSON.serialize(payloadWrp);
            
            ResponseWrapper responseWrapperObj = new ResponseWrapper();
            ABCL_IntegrationCallout.IntegrationResponseWrapper leadCreationWrp = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.SEND_LEAD_TO_CRM,payload,null);
            if(!Test.isRunningTest()){
                responseWrapperObj = responseWrapperObj.parse(leadCreationWrp.responseBody);
            }
            leadObj.API_Response_Message__c = '';
            leadObj.Create_Lead_To_CRM_Status__c = '';
            leadObj.API_Error_Code__c = '';
            leadObj.API_Error_Fields__c = ''; 
            if(responseWrapperObj.Status == '200'){
                leadObj.API_Response_Message__c = responseWrapperObj.Message;
                leadObj.Create_Lead_To_CRM_Status__c = 'Success';
                leadObj.Sales_Lead_Id__c = responseWrapperObj.id;
                message = 'Send Lead to CRM is Successful';
                try{
                    update leadObj;    
                }catch(Exception e){
                    system.debug('Error=='+e.getMessage());
                }
            }else{
                    message = responseWrapperObj.Message;
                if(responseWrapperObj.Message!=null){
                    leadObj.API_Response_Message__c = responseWrapperObj.Message.substring(0,Math.min(responseWrapperObj.Message.length(), 255));
                }
                    
                    leadObj.Create_Lead_To_CRM_Status__c = responseWrapperObj.status;
                    leadObj.API_Error_Code__c = responseWrapperObj.ErrorCode;
                    /*if(responseWrapperObj.Fileds != null && responseWrapperObj.Fileds.size() > 0){
                        leadObj.API_Error_Fields__c = string.join(responseWrapperObj.Fileds,',');
                    }*/
                    try{
                    	update leadObj;    
                    }catch(Exception e){
                        system.debug('Error=='+e.getMessage());
                    }
                	
					
                	if(!Test.isRunningTest() && !executingFromTrigger){
                        //throw new AuraHandledException('Send Lead to CRM Failed.');
                        return 'Send Lead to CRM Failed.Please check CRM Status Section for more Information.';
                    }
            }
            
            /*try{
                UPDATE leadObj;
            }catch(Exception e){
                system.debug('Error=='+e.getMessage());
            }*/
        }else{
            message = 'Lead is already created Successfully';
        }
        return message;
    }
    
    @future (callout=true)
    public static void executeSendLeadToCRM(set<Id> leadIdSet){
        List<Id> leadIdList = new List<Id>();
        leadIdList.addAll(leadIdSet);
        if(leadIdList.size() > 0){
        sendLead(leadIdList[0], true);

        }
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
        public String Email_ID;
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

        // Newly added parameters by Yogesh(EY) as requested by Business
        public string Lead_Stage;
        public string Source_Code;
        public string Campaign_Name;
        public string State;
        public string ABHFL_Employee_Number_Owner;
        public string Existing_Customer;
        public string Is_Property_Identified;
        public string Distributor_Code_Text;
        public string Country_Code;
        public string LAT;
        public string LOG;
        public string Street;
        public string GeocodeAccuracy;
        public string Property_Address_City;
        public string Property_Address_CountryCode;
        public string Property_Address_PostalCode;
        public string Property_Address_StateCode;
    
        // Constructor to map Lead fields to PayloadWrapper fields
        public PayloadWrapper(Lead leadObj) {
            this.Company_Name = leadObj.Company;
            this.Email_ID = leadObj.Email;
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
            /*Ishan - 14/05/2024
            Commenting the below code as ABHFL Gateway team needs First Name and Last Name 
            irrespective of ABHFL_Prospect_Type_c
            */
            //if(leadObj.ABHFL_Prospect_Type__c == 'Individual'){
            this.First_Name = leadObj.FirstName;
            this.Last_Name = leadObj.LastName;
            /*}else{
                this.First_Name = '';
                this.Last_Name = '';
            }*/

            this.SPOC_Name = leadObj.FirstName + ' ' + leadObj.LastName;
            //This parameters are requested by business in lead API
           // Added by Yogesh(EY)
            this.Lead_Stage = leadObj.Lead_Stage__c;
            this.Source_Code = leadObj.Source_Code__c;
            this.Campaign_Name = leadObj.Campaign_Name__c;
            this.State = leadObj.State__c;
            this.ABHFL_Employee_Number_Owner = leadObj.ABHFL_Employee_Number_Owner__c;
            this.Existing_Customer = leadObj.Existing_Customer__c;
            this.Is_Property_Identified = leadObj.Is_Property_Identified__c;
            this.Distributor_Code_Text = leadObj.Distributor_Code_Text__c;
            this.Country_Code = leadObj.Country_Code__c;
            this.LAT = leadObj.LAT__c;
            this.LOG = leadObj.LOG__c;
            this.Street = leadObj.Street__c;
            this.GeocodeAccuracy = leadObj.GeocodeAccuracy__c;
            this.Property_Address_City = leadObj.Property_Address_City__c;
            this.Property_Address_CountryCode = leadObj.Property_Address_CountryCode__c;
            this.Property_Address_PostalCode = leadObj.Property_Address_PostalCode__c;
            this.Property_Address_StateCode = leadObj.Property_Address_StateCode__c;
        }
    }

    
    public class ResponseWrapper{
        public String ErrorCode;
        public String Status;
        public String Message;
        public String id;
        public List<String> Fileds;
        
        public ResponseWrapper parse(String json) {
            return (ResponseWrapper) System.JSON.deserialize(json, ResponseWrapper.class);
        }
    }
}
