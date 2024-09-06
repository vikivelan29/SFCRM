/*********************************************************
*Class        :  ABHI_ClickPSSCommController
*Author       :  Amrit Preet Singh
*Created Date :  03/09/2024
*Last Modified:  03/09/2024
*@description  :  This class is the handler class to abhi_clickPSSCommController
*********************************************************/
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.FieldNamingConventions,PMD.VariableNamingConventions,PMD.ExcessivePublicCount')
public with sharing class ABHI_ClickPSSCommController {

    /****************************************************************************************************************
    * @Function - getMetadata
    * @return List<ABHI_PSSCommunicationConfig__mdt>
    * @param objectName - Name of the object for which the records are needed 
    * @description This method will return the list of metadata records for the object passed.
    *****************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<ABHI_PSSCommunicationConfig__mdt> getMetadata(String objectName){
        try {
            List<GroupMember> gpList = [SELECT GroupId, UserOrGroupId, Group.DeveloperName from GroupMember where UserOrGroupId =: UserInfo.getUserId() WITH SYSTEM_MODE];
            List<ABHI_PSSCommunicationConfig__mdt> pssCommList = new List<ABHI_PSSCommunicationConfig__mdt>();
            if(gpList.size()>0){
                Set<String> groupNameSet = new Set<String>();
                for(GroupMember gp : gpList){
                    groupNameSet.add(gp.Group.DeveloperName);
                }
                pssCommList = [SELECT Allowed_PS_Public_Group__c, CommunicationType__c, Entity__c,
                                                                    TemplateId__c, TemplateName__c, IsUserAllowed__c, Email_Field__c, Alert_Code__c, Phone_Field__c from ABHI_PSSCommunicationConfig__mdt where Entity__c =: objectName AND Allowed_PS_Public_Group__c IN: groupNameSet WITH SYSTEM_MODE]; 
            }
            
            return  pssCommList; 
               
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /****************************************************************************************************************
    * @Function - doCommunication
    * @return String
    * @param objectName - Name of the object for which the records are needed 
    * @param recordId - Id of the record
    * @param formData - form data of the record
    * @description This method will do the API call with the .
    *****************************************************************************************************************/
    @AuraEnabled
    public static ClientResponseWrapper doCommunication(String objectName, String recordId, String formData){
        try {
            String integrationName = 'ABHI_PSSCommunication';
            // RecordType rt = [SELECT Id from RecordType where DeveloperName = 'PSS'];
            String requestString = createRequest(objectName, recordId, formData);
            ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName,requestString,null);
            if(integrationResponse.responseBody != ''){
                Map<String,Object> objectMap = (Map<String,Object>) JSON.deserializeUntyped(integrationResponse.responseBody);
                integrationResponse.responseBody = JSON.serialize(objectMap);
            }
            if(integrationResponse.StatusCode == 200) {
                PSSResponseWrapper intResponse = (PSSResponseWrapper) JSON.deserialize(integrationResponse.responseBody, PSSResponseWrapper.class);
                    // Communication_History__c comHis = new Communication_History__c();
                    // comHis.Communication_Mode__c = intResponse.Alert_Mode == '2' ? 'SMS' : intResponse.Alert_Mode == '3' ? 'Email' : 'Whatsapp';
                    // comHis.Reference_Number__c = intResponse.REF_NO;
                    // comHis.RecordTypeId = rt.Id;
                    // comHis.Account__c = accountId;
                    // comHis.Template_Id__c = intResponse.alertID;
                    // insert comHis;
                if(intResponse.error == null){
                    return new ClientResponseWrapper(intResponse.StatusCode,Custom_Messages__mdt.getInstance('ABHI_Sent_Successfully').Message__c);
                }
                else{
                    return new ClientResponseWrapper(1001,intResponse.error.errorDesc);
                } 
            }
            else {
                try {
                    PSSResponseWrapper intResponse = (PSSResponseWrapper) JSON.deserialize(integrationResponse.responseBody, PSSResponseWrapper.class);
                    if(intResponse.ReturnMessage != null){
                        return new ClientResponseWrapper(integrationResponse.StatusCode,intResponse.ReturnMessage);
                    }
                    return new ClientResponseWrapper(integrationResponse.StatusCode,Custom_Messages__mdt.getInstance('ABHI_Communication_Failure').Message__c);
                } catch (Exception e) {
                    return new ClientResponseWrapper(integrationResponse.StatusCode,Custom_Messages__mdt.getInstance('ABHI_Communication_Failure').Message__c);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /****************************************************************************************************************
    * @Function - createRequest
    * @return String
    * @param objectName - Api Name of the object 
    * @param recordId - Record Id of the record 
    * @param formData - Data to be submitted
    * @description This method will create the request data for the API call.
    *****************************************************************************************************************/
    public static String createRequest(String objectName, String recordId, String formData){
        try {
            formWrapper formDataWrap = (formWrapper) JSON.deserialize(formData, formWrapper.class);
            PSSRequestWrapper reqWrap = new PSSRequestWrapper();
            Asset ass = [SELECT Policy_No__c, Next_Premium_Date__c, SerialNumber, Account.Phone, Account.Office_Email__c from Asset where id=: recordId];
            reqWrap.PolicyID = ass.Policy_No__c;
            reqWrap.AppNo = ass.SerialNumber;
            reqWrap.mobileno = formDataWrap.phoneNumber != ''? formDataWrap.phoneNumber : ass.Account.Phone;
            reqWrap.emailId = formDataWrap.emailId != ''? formDataWrap.emailId : ass.Account.Office_Email__c;
            reqWrap.channel_ID = 'SFCRM';
            reqWrap.Req_Id = '5696';
            reqWrap.Alert_Mode = formDataWrap.alertCode;
            reqWrap.alertID = formDataWrap.template;
            reqWrap.field1 = 'NA';
            reqWrap.field2 = 'NA';
            reqWrap.field3 = 'NA';
            return JSON.serialize(reqWrap);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    /*********************************************************
    *Class        :  FormWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  03/09/2024
    *Last Modified:  03/09/2024
    *@description  : This is the wrapper class to hold the details sent from client during run time
    *********************************************************/
    public class FormWrapper{
        public String commType;
        public String template;
        public String alertCode;
        public String phoneNumber;
        public String emailId;
    }

    /*********************************************************
    *Class        :  ClientResponseWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  03/09/2024
    *Last Modified:  03/09/2024
    *@description  : This is the wrapper class to hold the response to send to the client side
    *********************************************************/
    public class ClientResponseWrapper{
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String message;
        /**
         * @description parameterized constructor
         * @param statusCode - Returned Status Code
         * @param message  - Message to be passed
         */
        public ClientResponseWrapper(Integer statusCode, String message){
            this.statusCode = statusCode;
            this.message = message;
        }
    }

    /*********************************************************
    *Class        :  PSSRequestWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  03/09/2024
    *Last Modified:  03/09/2024
    *@description  : This is the wrapper class to hold the request that we'll send for the API call
    *********************************************************/
    public class PSSRequestWrapper{
        public String PolicyID;
        public String AppNo;
        public String AlertID;
        public String ChannelID;
        public String ReqId;
        public String AlertMode;
        public String Mobileno;
        public String EmailId;
        public String Field1;
        public String Field2;
        public String Field3;
    }

    /*********************************************************
    *Class        :  PSSResponseWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  03/09/2024
    *Last Modified:  03/09/2024
    *@description  : This is the wrapper class to hold the response that we recieve from the API
    *********************************************************/
    @SuppressWarnings('PMD.TooManyFields')
    public class PSSResponseWrapper{
        @AuraEnabled public String PolicyID;
        @AuraEnabled public String FIELD3;
        @AuraEnabled public String AppNo;
        @AuraEnabled public String alertID;
        @AuraEnabled public String channel_ID;
        @AuraEnabled public String Req_Id;
        @AuraEnabled public String Alert_Mode;
        @AuraEnabled public String REF_NO;
        @AuraEnabled public String EMLFLG;
        @AuraEnabled public String SMSFLG;
        @AuraEnabled public String STATUS;
        @AuraEnabled public String field1;
        @AuraEnabled public String field2;
        @AuraEnabled public ErrorWrapper error;
        @AuraEnabled public Integer StatusCode;
        @AuraEnabled public String message;
        @AuraEnabled public String ReturnCode;
        @AuraEnabled public String ReturnMessage;
    }

    /*********************************************************
    *Class        :  ErrorWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  03/09/2024
    *Last Modified:  03/09/2024
    *@description  : This is the wrapper class to hold the error response that we recieve from the API
    *********************************************************/
    public class ErrorWrapper{
        @AuraEnabled public String errorcode;
        @AuraEnabled public String errorDesc;
    }
}