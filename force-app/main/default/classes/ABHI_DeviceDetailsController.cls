/*********************************************************
*Class        :  ABHI_DeviceDetailsController
*Author       :  Amrit Preet Singh
*Created Date :  05/08/2024
*Last Modified:  05/08/2024
*@description  :  ABHI_DeviceDetailsController is used as an apex controller for the abhi_FAHistoryDetails
*@description  :  This class is used to get the Device Details calling the ABCL_IntegrationCallout callout class.
*@description  :  The class is used to get the device details for the customerId passed.
*********************************************************/
public with sharing class ABHI_DeviceDetailsController {

    /****************************************************************************************************************
    * @Function - getDeviceDetails
    * @param requestPayload - Payload to be passed for requesting the data
    * @param customerId - Id of the customer record
    * @return - ResponseWrapper - Wrapper including the needed device details
    * @description - This method is used to get the Device details for the customer id passed.
    *****************************************************************************************************************/
    @AuraEnabled
    public static ResponseWrapper getDeviceDetails(String customerId){
        try {
            String integrationName = 'ABHI_DeviceDetails';
            ABCL_IntegrationCallout.accountId = customerId;
            List<Account> acc = [SELECT Client_Code__c from Account where Id =: customerId];
            String code = acc[0].Client_Code__c != null && acc[0].Client_Code__c != ''  ? acc[0].Client_Code__c : '0';
            if(code == '0'){
                return new ResponseWrapper(
                    400,
                    Custom_Messages__mdt.getInstance('ABHI_Customer_Id_Mandatory').Message__c
                );
            }
            String requestPayload = JSON.serialize(new RequestWrapper(code,'android','',''));
            ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName,requestPayload,null);
            if(integrationResponse.responseBody != ''){
                EncryptedResponseWrapper encryptedResponse = (EncryptedResponseWrapper) JSON.deserialize(integrationResponse.responseBody, EncryptedResponseWrapper.class);
                if(encryptedResponse.Content == null || encryptedResponse.Content == ''){
                    String returnMessage = encryptedResponse.Message != null ? encryptedResponse.Message : Custom_Messages__mdt.getInstance('ABHI_DeviceDetailsNotFound').Message__c;
                    return new ResponseWrapper(Integer.valueOf(integrationResponse.StatusCode), returnMessage);
                }
                String decryptedResponse = ABHI_Encryption.decrypt(encryptedResponse.Content, integrationName);
                if(integrationResponse.StatusCode == 200 && encryptedResponse.StatusCode == '1000'){
                    String responseDecryptedBody = (String) JSON.deserializeUntyped(decryptedResponse);
                    deserilaizedResponse deserializedIntResponse = (deserilaizedResponse) JSON.deserialize(responseDecryptedBody, deserilaizedResponse.class);
                    ResponseWrapper returnResponse = new ResponseWrapper(Integer.valueOf(encryptedResponse.StatusCode), encryptedResponse.Message, deserializedIntResponse.data.devices);
                    return returnResponse;
                }
                else{
                    String returnMessage = decryptedResponse != '' ? (String) JSON.deserializeUntyped(decryptedResponse) : encryptedResponse.Message;
                    ResponseWrapper returnResponse = new ResponseWrapper(Integer.valueOf(encryptedResponse.StatusCode), returnMessage);
                    return returnResponse;
                }
            }
            else{
                ResponseWrapper returnResponse = new ResponseWrapper(Integer.valueOf(integrationResponse.StatusCode), Custom_Messages__mdt.getInstance('ABHI_DeviceDetailsNotFound').Message__c);
                return returnResponse;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*********************************************************
    *Class        :  RequestWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  23/08/2024
    *Last Modified:  23/08/2024
    *@description  :  Wrapper class to hold the request JSON to send 
    *********************************************************/
    public class RequestWrapper{
        public String MemberID;
        public String OS;
        public String PolicyStartDate;
        public String WellnessID;
        public RequestWrapper(String memberId, String OS, String policyDate, String wellnessId){
            this.MemberID = memberId;
            this.OS = OS;
            this.PolicyStartDate = policyDate;
            this.WellnessID = wellnessId;
        }
    }

    /*********************************************************
    *Class        :  EncryptedResponseWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  23/08/2024
    *Last Modified:  23/08/2024
    *@description  :  EncryptedResponseWrapper is wrapper class to hold encrypted response
    *********************************************************/
    public class EncryptedResponseWrapper{
        public String Content;
        public String StatusCode;
        public String Message;
    }

    /*********************************************************
    *Class        :  RecommendedWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  :  RecommendedWrapper is a wrapper class to hold device details
    *********************************************************/
    public class RecommendedWrapper {
        @AuraEnabled
		public String logo_url;
        @AuraEnabled
		public String name;
        @AuraEnabled
		public String subname;
        @AuraEnabled public String sync_url;
        @AuraEnabled public String synced;
        @AuraEnabled public String redirect_uri;
        @AuraEnabled public GooglefitProfile googlefitProfile;
	}

    /*********************************************************
    *Class        :  GooglefitProfile
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  :  GooglefitProfile is a wrapper class to hold the google profile details for a device
    *********************************************************/
    public class GooglefitProfile {
        @AuraEnabled public String Display_Name;
        @AuraEnabled public String Email;
        @AuraEnabled public Object Family_Name;
        @AuraEnabled public String Given_Name;
        @AuraEnabled public String ID;
        @AuraEnabled public String ID_Token;
        @AuraEnabled public String Server_Auth_Code;
        @AuraEnabled public String Photo_URL;
	}

    /*********************************************************
    *Class        :  Data
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  :  Data is a wrapper class to hold device categories and details
    *********************************************************/
	public class Data {
        public List<String> deviceCategories;
        public Devices devices;
	}

    /*********************************************************
    *Class        :  BookingHistoryWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  :  BookingHistoryWrapper is a wrapper class to hold Booking History Information
    *********************************************************/
	public class Devices {
        @AuraEnabled public List<RecommendedWrapper> Recommended;
        @AuraEnabled public List<RecommendedWrapper> Others;
	}

    /*********************************************************
    *Class        :  deserilaizedResponse
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  :  deserilaizedResponse is a wrapper class to hold the deserialiized response from the server
    *********************************************************/
    public class deserilaizedResponse{
        public Integer code;
        public String msg;
        public Object error;
        public String Message;
        public Data data;
        public String StatusCode;
    }

    /*********************************************************
    *Class        :  ResponseWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  :  ResponseWrapper is a wrapper class to hold the response needed to return to the LWC component
    *********************************************************/
    public class ResponseWrapper{
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String Message;
        @AuraEnabled public Devices devices;
        public ResponseWrapper(Integer code, String Message, Devices device){
            this.statusCode = code;
            this.Message = Message;
            this.devices = device;
        }
        public ResponseWrapper(Integer code, String Message){
            this.statusCode = code;
            this.Message = Message;
        }
    }

}