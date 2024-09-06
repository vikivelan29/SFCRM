/*********************************************************
*Class        :  ABHI_FAHistoryDetailsController
*Author       :  Amrit Preet Singh
*Created Date :  05/08/2024
*Last Modified:  05/08/2024
*@description  :  ABHI_FAHistoryDetailsController is used as an apex controller for the ABHI_FAHistoryDetailsComponent
*@description  :  This class is used to get the FA History Details from the ABCL_IntegrationCallout callout class.
*@description  :  The class is used to get the appointment details for the customerId passed.
*********************************************************/
public with sharing class ABHI_FAHistoryDetailsController {

    /****************************************************************************************************************
    * @Function - evaluateCasesForOneABC
    * @param customerId - Customer Id for which the Fitness APpointmtnt History has to be searched
    * @return - IntegrationResponseWrapper
    * @description - This method is used to get the Fitness Apppointment History details for the customer id passed.
    *****************************************************************************************************************/
    @AuraEnabled
    public static IntegrationResponseWrapper getFADetails(String customerId){
        try {
            String integrationName = 'ABHI_FAHistoryDetails';
            ABCL_IntegrationCallout.accountId = customerId;
            List<Account> acc = [SELECT Client_Code__c from Account where Id =: customerId];
            Map<String, String> urlParams = new Map<String, String>();
            String code = acc[0].Client_Code__c != null && acc[0].Client_Code__c != ''  ? acc[0].Client_Code__c : '0';
            if(code == '0'){
                return new IntegrationResponseWrapper(
                    400,
                    Custom_Messages__mdt.getInstance('ABHI_Customer_Id_Mandatory').Message__c
                );
            }

            urlParams.put('customerId', code);
            ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName,'',urlParams);
            
            if(integrationResponse.StatusCode == 200) {
                IntegrationResponseWrapper deserializedIntResponse = (IntegrationResponseWrapper) JSON.deserialize(integrationResponse.responseBody, IntegrationResponseWrapper.class);
                return deserializedIntResponse;
            }
            else {
                return new IntegrationResponseWrapper(
                    integrationResponse.StatusCode,
                    Custom_Messages__mdt.getInstance('ABHI_FAHistoryNotFound').Message__c
                );
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*********************************************************
    *Class        :  BookingHistoryWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  :  BookingHistoryWrapper is a wrapper class to hold Booking History Information
    *********************************************************/
    public class BookingHistoryWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String status;
        @AuraEnabled public String bookingSlot;
        @AuraEnabled public String comments;
        @AuraEnabled public String createdBy;
        @AuraEnabled public String appointmentDate;
        @AuraEnabled public String createdDate;
        @AuraEnabled public String fitnessCenterBranch;
    }

    /*********************************************************
    *Class        :  IntegrationResponseWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  :  IntegrationResponseWrapper is the wrapper class to hold Response to return to the LWC component
    *********************************************************/
    public class IntegrationResponseWrapper {
        @AuraEnabled public InfoWrapper info;
        @AuraEnabled public List<CustomerAppointmentsWrapper> customerAppointments;
        @AuraEnabled public Integer StatusCode;	
	    @AuraEnabled public String Message;	
        public IntegrationResponseWrapper(Integer statusCode, String responseBody){
            this.StatusCode = statusCode;
            this.Message = responseBody;
        }
    }

    /*********************************************************
    *Class        :  InfoWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  :  InfoWrapper is the wrapper class to hold the information of the info JSON from response
    *********************************************************/
    public class InfoWrapper{
        @AuraEnabled public String status;
        @AuraEnabled public String messageCode;
        @AuraEnabled public String messageDesc;
        @AuraEnabled public String serviceMessageType;
    }

    /*********************************************************
    *Class        :  CustomerAppointmentsWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  : CustomerAppointmentsWrapper is the wrapper class to hold the information of Customer Appointment from response
    *********************************************************/
    public class CustomerAppointmentsWrapper{
        @AuraEnabled public String bookingId;
        @AuraEnabled public List<BookingHistoryWrapper> bookingHistories;  
    }
}