/***************************************
*Class        :  ABHI_CreateClaimService
*Author       :  Kuldeep Mishra
*Created Date :  23/08/2024
*Last Modified:  02/09/2024
*@description :  This webservice is to create Claim records in SFDC.
***************************************/
@RestResource (urlMapping='/CreateClaim')
global class ABHI_CreateClaimService {
    
    
    @HttpPost
        global static String doPost(){
           ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
           String accountId;
           Boolean hasError = false;
           Map<String, Map<String, String>> mapObjectFieldMapping = new Map<String, Map<String, String>>();
            Asset AssetPolicy = null;
            Sobject refObject = null;        
            
   List<Map<String, Object>> requestBodyList = new List<Map<String, Object>>(); 
               List<Claim__c> claimsToProcess= new list<Claim__C>();
          
            list<requestListWrapper> requestBody = new list<requestListWrapper>();            
            for(ABHI_Field_Mapping__mdt fieldMap : [SELECT ID, ABHI_Field_API_Name__c, ABHI_JSON_Field_Name__c,
                                                 ABHI_Object_Mapping__r.DeveloperName, ABHI_Type__c, ABHI_Field_Type__c
                                                 FROM ABHI_Field_Mapping__mdt 
                                                 WHERE ABHI_Object_Mapping__r.DeveloperName ='Claim']) {
                                                     if(!mapObjectFieldMapping.containsKey(fieldMap.ABHI_Object_Mapping__r.DeveloperName)) {
                                                         mapObjectFieldMapping.put(fieldMap.ABHI_Object_Mapping__r.DeveloperName, new Map<String, String>());
                                                         }
                                                         mapObjectFieldMapping.get(fieldMap.ABHI_Object_Mapping__r.DeveloperName).put(fieldMap.ABHI_JSON_Field_Name__c, fieldMap.ABHI_Field_API_Name__c);
                                                     System.debug('Field Mapping: JSON Field - ' + fieldMap.ABHI_JSON_Field_Name__c +', API Field - ' +fieldMap.ABHI_Type__c + ', API Field - ' + fieldMap.ABHI_Field_API_Name__c);
                                                 }
            
              
            try {
                 String requestBodyStr = RestContext.request.requestBody.toString();
            System.debug('Raw Request Body: ' + requestBodyStr);
                 List<requestListWrapper> requestList = (List<requestListWrapper>) JSON.deserialize(requestBodyStr, List<requestListWrapper>.class);

                for(requestListWrapper wrap : requestList){
                    requestBodyList.add((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(wrap)));
                    for(Map<String, Object> item: requestBodyList){ //(Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(wrap));
                    String ClaimNumber = (String) item.get('Claim_Number');
                    String policyNumber = (String) item.get('Policy_Number');
                        system.debug(item);
                                      // Map JSON fields to Salesforce fields
                     Claim__c claim = new Claim__c();
                     Map<String, String> fieldMapping = mapObjectFieldMapping.get('Claim');
                if(fieldMapping != null) {
                    for (String jsonField : mapObjectFieldMapping.get('Claim').keySet()) {
                        system.debug('jsonField-->' +jsonField);                  
                        String apiFieldName = fieldMapping.get(jsonField);
                        Object fieldValue = item.get(jsonField); 
                       System.debug('JSON Field: ' + jsonField + ', API Field: ' + apiFieldName + ', Value: ' + fieldValue);
                        
                            if(fieldValue != null) {
                                try {
                                if(apiFieldName.contains('__r')) {
                                     String[] parts = apiFieldName.split('\\.');
                                    if (parts.size() > 1) {
                                        String relationshipField = parts[0];
                                        String relatedField = parts[1];
                                    
                                    if( relationshipField == 'Policy_Number__r') {      //apiFieldName.equals('Policy_Number__r.ABHI_Policy_Id__c')
                                        claim.Policy_Number__r = new Asset(ABHI_Policy_Id__c = (String) fieldValue); 
                                        system.debug('claim.Policy_Number__r' +claim.Policy_Number__r);
                                    }else if (relationshipField == 'Hospital_Code__r') {   //apiFieldName.equals('Hospital_Code__r.Provider_Code__c')
                                            claim.Hospital_Code__r = new Health_Provider__c(Provider_Code__c = (String) fieldValue);
                                          system.debug('claim.Hospital_Code__r' +claim.Hospital_Code__r);
                                        
                                        }else if (relationshipField == 'Customer_Member_Mapping__r') {
                                            claim.Customer_Member_Mapping__r = new Account(LOB_Client_Code__c = (String) fieldValue);
                                        } else { 
                                        claim.put(apiFieldName, fieldValue);// Other relationship fields
                                    }
                                        } else {
                                        claim.put(apiFieldName, fieldValue);
                                    }
                                } else {
                        // Check for Date and DateTime fields
                        Schema.SObjectField fieldToken = Claim__c.SObjectType.getDescribe().fields.getMap().get(apiFieldName);
                        Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
                        if (fieldDescribe.getType() == Schema.DisplayType.DATE || fieldDescribe.getType() == Schema.DisplayType.DATETIME) {
                            if (fieldDescribe.getType() == Schema.DisplayType.DATE) {
                                claim.put(apiFieldName, Date.valueOf(fieldValue.toString()));
                            } else if (fieldDescribe.getType() == Schema.DisplayType.DATETIME) {
                                claim.put(apiFieldName, parseDateTime(fieldValue.toString()));
                            }
                        }else if (fieldDescribe.getType() == Schema.DisplayType.CURRENCY) {
                            Decimal currencyValue = parseCurrency(fieldValue.toString());
                            claim.put(apiFieldName, currencyValue);
                        } else {
                            claim.put(apiFieldName, fieldValue);
                               }
                            }
                            } catch (Exception e){
                                System.debug('Error setting field value for ' + apiFieldName + ': ' + e.getMessage());
                            } 
                        }                    
                     }
                  }
                       //claim.name = claimNumber;
                    claim.ClaimExternalId__c = claimNumber;
                              claimsToProcess.add(claim);
                    }                    
                } 
                // Upsert claims
            if (!claimsToProcess.isEmpty()) {
                try{
                upsert claimsToProcess ClaimExternalId__c;
                    return JSON.serialize(new ABHI_ResponseWrapper('200', 'Success', Custom_Messages__mdt.getInstance('ABHI_SuccessMessage').Message__c));
                }catch (DmlException e) {
                integrationResponse.responseBody = logError(e.getMessage(), requestBody);
                hasError = true;
            }
            }
        }catch (Exception e){
            integrationResponse.responseBody = logError(Custom_Messages__mdt.getInstance('ABHI_InvalidJson').Message__c, requestBody);
            hasError = true;        
        }
            return integrationResponse.responseBody;
    }
    
    // Utility method to parse currency strings
private static Decimal parseCurrency(String currencyStr) {
    try {
        if (currencyStr != null){
            // Remove common currency symbols and commas
            String cleanedCurrencyStr = currencyStr.replaceAll('[^0-9.-]', '');
            // Convert cleaned string to Decimal
            Decimal parsedDecimal = Decimal.valueOf(cleanedCurrencyStr);
            return parsedDecimal;
        }
      } catch (Exception e){
        System.debug('Currency parsing error: ' + e.getMessage());
        }
        return null;
}
     // Utility method to parse DateTime strings
     private static DateTime parseDateTime(String dateTimeStr) {
    try {
        if (dateTimeStr != null) {
            // Remove the 'Z' if present and replace 'T' with a space
            String formattedDateTimeStr = dateTimeStr.replace('Z', '').replace('T', ' ');
            // Convert to DateTime
            return DateTime.valueOf(formattedDateTimeStr);
        }
      } catch (Exception e) {
        System.debug('DateTime parsing error: ' + e.getMessage());
    }
    return null;
}
    
    
    //wrapper class to hold the request Body.
    public class requestwrapper{
        public list<requestListWrapper> Request;
    }
    public class requestListWrapper{
        
        public String Request_Type;
        public String Claim_Number;
        public String Claim_Type;
        public String Claim_SubType;
        public String Claim_Status;
        public String Claim_Amount;
        public String Total_amount_approved;
        public String ClaimDate;
        public String Paid_Amount;
        public String Member_Name;
        public String Policy_Number;
        public String Patient_Name;
        public String Policy_Status;
        public String Hospital_Name;
        public String Date_of_admission;
        public String Diagnosis;
        public String Intimation_Type;
        public String Customer_Member_Mapping;
        public String FamilyId;
        public String Cover_Name;
        public String Cover_Code;
        public String Hospital_Code;
        public String Date_of_discharge;
        public String Hospital_Contact_Number;
        public String Room_Eligibility;
        public String Co_Payment;
        public String Deducted_amount;
        public String Deduction_Reasons;
        public String Balance_Sum_Insured;
        public String Repudiation_Reasons;
        public String Chronic_tagging;
        public String Sales_Person_Name;
        public String Sales_Person_Empi_Id;
        public String Account_Number;
        public String UTR_Number;
        public String Beneficiary_Name;
        public String Benefit_info;
        public String Provider_Code;
        public String Rohini_Code;
        public String Provider_Type;
        public String Network_Type;
        public String Provider_Status;
        public String Reverse_Amount;
        public String Health_Return_Amount;
        public String claim_Intimation_received_date;
        public String Settlement_Date;
        
    }
    
     
    //@description - This method is used to log the error if any occurs during the request.
     private static String logError(String errorMsg, List<requestListWrapper> requestBody){
        ASF_Case_Integration__c integrationLog = new ASF_Case_Integration__c();
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        Boolean hasError = true;
        ABCL_Integrations__mdt  integrationMdt = ABCL_IntegrationCallout.getIntegrationMetadata('ABHI_CreateHealthIntent_Inbound');
        ABHI_ResponseWrapper abhiResponse = new ABHI_ResponseWrapper('100', 'Failure', errorMsg);
        //abhiResponse.responseBody = JSON.serialize(requestBody);
        integrationResponse.responseBody = JSON.serialize(abhiResponse)+ JSON.serialize(requestBody);
        hasError = true;
        ABHI_ResponseWrapper.createLog(integrationLog,integrationMdt, integrationResponse, hasError);
        ABCL_IntegrationCallout.handleResponse(integrationMdt, integrationResponse, hasError);
        return integrationResponse.responseBody;
    }

}