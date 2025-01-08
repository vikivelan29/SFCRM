/*********************************************************
 *Class        :  ABSLI_PIVCModernization 
 *Author       :  
 *Created Date :  
 *Last Modified:  
 *Description  :  Sending Case To External system
 *********************************************************/

public with sharing class ABSLI_PIVCModernization {
    public static string sendcase(Id caseId) {
        system.debug('Inside Send Case method'+caseId);
        String integrationName = ABCL_Integrations__mdt.getInstance('ABSLI_PIVC_Integration').DeveloperName; 
        system.debug('integration Name '+integrationName);
        String message;
        String errorCode;
        Case caseObj = new Case();
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        //try {
            system.debug('inside try '+caseObj);
            
            caseObj = [SELECT Id, CaseNumber, ABSLI_Case_Detail__r.API_Error_Code__c, ABSLI_Case_Detail__r.API_Response_Message__c, Asset.Application_Number__c
                      ,ABSLI_Case_Detail__c FROM Case WHERE Id =: caseId
                      ];
            caseDetail = [Select Id, API_Request__c,API_Name__c,API_Response_Message__c,API_Error_Code__c from ABSLI_Case_Detail__c where Id = :caseObj.ABSLI_Case_Detail__c];
            //system.debug('chk case'+caseObj);
        //} catch (Exception e) {
         //   system.debug('Error==' + e.getMessage());
        //}
        If( caseObj != null && caseObj.Asset.Application_Number__c != null ) {
            PayloadWrapper payloadWrp = new PayloadWrapper(caseObj);
            String payload = JSON.serialize(payloadWrp);
            
            ResponseWrapper responseWrapperObj = new ResponseWrapper();
            ABCL_IntegrationCallout.IntegrationResponseWrapper caseSendingWrp = ABCL_IntegrationCallout.executeCallout(integrationName, payload, null);
            //ABCL_IntegrationCallout.IntegrationResponseWrapper caseSendingWrp = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
            //caseSendingWrp.responseBody = '{"message": "error", "ErrorCode":"Er0012", "Status":"400"}';
            //caseSendingWrp.responseBody = '{"message": "Success", "Status":"200"}';
            system.debug('check 28 Line '+caseSendingWrp);
                responseWrapperObj = responseWrapperObj.parse(caseSendingWrp.responseBody);
            caseDetail.API_Name__c='PIVC Verisafe';
            caseDetail.API_Request__c=payload;
            caseDetail.API_Response_Message__c = '';
            caseDetail.API_Error_Code__c = '';
            if (responseWrapperObj.Status == '200') {
                caseDetail.API_Response_Message__c = responseWrapperObj.Message;
                message = 'Send Case to CRM is Successful';
                try {
                    update caseDetail;
                } catch (Exception e) {
                    system.debug('Error==' + e.getMessage());
                }
            } else {
                
                if(responseWrapperObj.Fault != null){
                    message = responseWrapperObj.Fault.FaultMessage;
                    errorCode = responseWrapperObj.Fault.FaultCode;
                }
                else{
                    message = responseWrapperObj.Message;
                    errorCode = responseWrapperObj.code;
                }
                
                if (message != null) {
                    caseDetail.API_Response_Message__c = message.substring(0, Math.min(message.length(), 255));
                }
                //caseObj.ABSLI_Case_Detail__r.API_Response_Message__c  = responseWrapperObj.status;
                caseDetail.API_Error_Code__c = errorCode;
                try {
                    update caseDetail;
                } catch (Exception e) {
                    system.debug('Error==' + e.getMessage());
                }
            }
            if (!Test.isRunningTest()) {
                //throw new AuraHandledException('Send Lead to CRM Failed.');
                return 'Send Lead to CRM Failed.Please check CRM Status Section for more Information.';
            }
        }
        else {
            message = 'Case is not Sent';
        }
        return message;
    }
    
    @future(callout = true)
    public static void executeSendCaseToCRM(set < Id > CaseIdSet) {
        List < Id > caseIdList = new List < Id > ();
        caseIdList.addAll(CaseIdSet);
        if (caseIdList.size() > 0) {
            sendcase(caseIdList[0]);
        }
    }
    
    public class PayloadWrapper {
        public String App_No;
        public String Interaction_ID;
        
        // Constructor to map Lead fields to PayloadWrapper fields
        public PayloadWrapper(Case caseObj) {
            this.App_No = caseObj.Asset.Application_Number__c;
            this.Interaction_ID = caseObj.CaseNumber;
        }
    }
    
    public class ResponseWrapper {
        public String ErrorCode;
        public String Status;
        public String Message;
        public String code;
        public String id;
        public List < String > Fileds;
        public FaultWrapper fault;
        public ResponseWrapper parse(String json) {
            return (ResponseWrapper) System.JSON.deserialize(json, ResponseWrapper.class);
        }
    }
    public class FaultWrapper {
        public String FaultCode;
        public String FaultMessage;
        
        
    }
}
