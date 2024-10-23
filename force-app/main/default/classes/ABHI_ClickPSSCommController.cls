/*********************************************************
*Class        :  ABHI_ClickPSSCommController
*Author       :  Amrit Preet Singh
*Created Date :  03/09/2024
*Last Modified:  03/09/2024
*@description  :  This class is the handler class to abhi_clickPSSCommController
*********************************************************/
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
            List<GroupMember> gpList = [SELECT GroupId, UserOrGroupId, Group.DeveloperName from GroupMember where UserOrGroupId =: UserInfo.getUserId()];
            List<ABHI_PSSCommunicationConfig__mdt> pssCommList = new List<ABHI_PSSCommunicationConfig__mdt>();
            if(gpList.size()>0){
                Set<String> groupNameSet = new Set<String>();
                for(GroupMember gp : gpList){
                    groupNameSet.add(gp.Group.DeveloperName);
                }
                pssCommList = [SELECT Allowed_PS_Public_Group__c, CommunicationType__c, Entity__c,
                                                                    TemplateId__c, TemplateName__c, IsUserAllowed__c, Email_Field__c, Alert_Code__c, Phone_Field__c from ABHI_PSSCommunicationConfig__mdt where Entity__c =: objectName AND Allowed_PS_Public_Group__c IN: groupNameSet]; 
            }
            return  pssCommList; 
               
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /****************************************************************************************************************
    * @Function - doCommunication
    * @return String
    * @param requestString - Request to be passed to the service 
    * @description This method will do the API call with the .
    *****************************************************************************************************************/
    @AuraEnabled
    public static ClientResponseWrapper doCommunication(String objectName, String recordId, String formData){
        try {
            String integrationName = 'ABHI_PSSCommunication';
            
            // RecordType rt = [SELECT Id from RecordType where DeveloperName = 'PSS'];
            String requestString = createRequest(objectName, recordId, formData);
            System.debug('requestString>>>'+requestString);
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
                else return new ClientResponseWrapper(1001,intResponse.error.errorDesc);
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
            ABHI_PSSCommunicationConfig__mdt mtdt = [SELECT TemplateName__c, Email_Field__c, Alert_Code__c, Phone_Field__c, ALERTV1__c, ALERTV2__c, ALERTV3__c, ALERTV4__c, ALERTV5__c, ALERTV6__c, ALERTV7__c, ALERTV8__c, ALERTV9__c, ALERTV10__c, ALERTV11__c, ALERTV12__c, ALERTV13__c, ALERTV14__c, ALERTV15__c, ALERTV16__c, ALERTV17__c, ALERTV18__c, ALERTV19__c, ALERTV20__c, ALERTV21__c, ALERTV22__c, ALERTV23__c, ALERTV24__c, ALERTV25__c, ALERTV26__c, ALERTV27__c, ALERTV28__c, ALERTV29__c, ALERTV30__c, ALERTV31__c, ALERTV32__c, ALERTV33__c, ALERTV34__c, ALERTV35__c, ALERTV36__c, ALERTV37__c, ALERTV38__c, ALERTV39__c, ALERTV40__c from ABHI_PSSCommunicationConfig__mdt where TemplateId__c =: formDataWrap.template AND Entity__c =: objectName AND CommunicationType__c =:formDataWrap.commType ];
            String query = 'SELECT Policy_No__c, Next_Premium_Date__c, SerialNumber, AccountId, Account.Phone, Account.Office_Email__c';
            // query = mtdt.Email_Field__c != null? query+', '+mtdt.Email_Field__c : query;
            // query = mtdt.Phone_Field__c != null? query+', '+mtdt.Phone_Field__c : query;
            for(Integer i=1;i<41;i++){
                query = mtdt.get('ALERTV'+i+'__c') != null? query+', '+ mtdt.get('ALERTV'+i+'__c') : query;
            }
            query += ' from Asset where id=:recordId';
            Sobject sobj = Database.query(query);
            System.debug('sobj>>'+sobj);
            //Asset ass = [SELECT Policy_No__c, Next_Premium_Date__c, SerialNumber, Account.Phone, Account.Office_Email__c, AccountId from Asset where id=: recordId];
            reqWrap.PolicyID = String.valueOf(sobj.get('Policy_No__c'));
            ABCL_IntegrationCallout.accountId = String.valueOf(sobj.get('AccountId'));
            reqWrap.AppNo = String.valueOf(sobj.get('SerialNumber'));
            reqWrap.mobileno = formDataWrap.phoneNumber != ''? formDataWrap.phoneNumber : String.valueOf(sobj.getSobject('Account').get('Phone'));
            reqWrap.emailId = formDataWrap.emailId != ''? formDataWrap.emailId : String.valueOf(sobj.getSobject('Account').get('Office_Email__c'));
            reqWrap.channel_ID = 'SFCRM';
            reqWrap.Req_Id = '5696';
            reqWrap.Alert_Mode = formDataWrap.alertCode;
            reqWrap.alertID = formDataWrap.template;
            reqWrap.field1 = 'NA';
            reqWrap.field2 = 'NA';
            reqWrap.field3 = 'NA';
            String reqWrapString = JSON.serialize(reqWrap);
            Map<String,Object> obj =  (Map<String,Object>) JSON.deserializeUntyped(reqWrapString);
            
            for(Integer i=1;i<41;i++){
                String field = '';
                if(mtdt.get('ALERTV'+i+'__c') != null && String.valueOf(mtdt.get('ALERTV'+i+'__c')).contains('.')){
                    field = String.valueOf(sobj.getSobject(String.valueOf(mtdt.get('ALERTV'+i+'__c')).split('\\.')[0]).get(String.valueOf(mtdt.get('ALERTV'+i+'__c')).split('\\.')[1]));
                }
                else if(mtdt.get('ALERTV'+i+'__c') != null){
                    field=String.valueOf(sobj.get(String.valueOf(mtdt.get('ALERTV'+i+'__c'))));
                }
                else field = '';
                Object ov = (Object) field;
                obj.put('AlertV'+i, ov);
            }
            System.debug('obj>>>>'+obj);
            return JSON.serialize(obj);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    /*********************************************************
    *Class        :  formWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  03/09/2024
    *Last Modified:  03/09/2024
    *@description  : This is the wrapper class to hold the details sent from client during run time
    *********************************************************/
    public class formWrapper{
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
        public String alertID;
        public String channel_ID;
        public String Req_Id;
        public String Alert_Mode;
        public String mobileno;
        public String EmailId;
        public String field1;
        public String field2;
        public String field3;
    }

    /*********************************************************
    *Class        :  PSSResponseWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  03/09/2024
    *Last Modified:  03/09/2024
    *@description  : This is the wrapper class to hold the response that we recieve from the API
    *********************************************************/
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
        @AuraEnabled public errorWrapper error;
        @AuraEnabled public Integer StatusCode;
        @AuraEnabled public String message;
        @AuraEnabled public String ReturnCode;
        @AuraEnabled public String ReturnMessage;
    }

    /*********************************************************
    *Class        :  errorWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  03/09/2024
    *Last Modified:  03/09/2024
    *@description  : This is the wrapper class to hold the error response that we recieve from the API
    *********************************************************/
    public class errorWrapper{
        @AuraEnabled public String errorcode;
        @AuraEnabled public String errorDesc;
    }
}