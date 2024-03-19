/**
 * @description       =>
 * @author            =>rsinghnagar@salesforce.com
 * @group             =>
 * @last modified on  =>03-06-2024
 * @last modified by  =>rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   03-06-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class ABFL_InvokeENachProcess {
   private static Map<String, Object> dummyInPayloadWrap = new Map<String, Object>{ 
        'pl_merchant_id'=>'MRC8821',
        'customer_Id'=>'7406498698',
        'customer_mobile_no'=>'7498791441',
        'customer_name'=>'Vaibhav',
        'customer_email_id'=>'guest@phicommerce.com',
        'customer_bank_ifsc'=>'UTIB0000305',
        'customer_bank_acc_no'=>'921010038015673',
        'amount'=>'10.00',
        'start_date'=>'20240224',
        'end_date'=>'20240816',
        'frequency'=>'V',
        'debit_type'=>'MAXAMOUNT',
        'return_url'=>'http://localhost:8090/resultpage'
    };
    private static Map<String, Object> dummyPayloadWrap = new Map<String, Object>{ 
        'enach_data' => dummyInPayloadWrap
    };

    private static Map<String, Object> dummyInResponseWrap = new Map<String, Object>{ 
        'pl_enach_id'=>'7406498698',
        'created_date'=>'20240205',
        'registration_link'=>
        'https://paymentloungeuat.adityabirlacapital.com/pg/portal/pay/enachRequest?requestID=7406498698&actionType=viewRequest&merchantid=T_88821',
        'return_code'=>'0000',
        'resp_description'=>'Request Processed Successfully'    
    };
    private static Map<String, Object> dummyResponseWrap = new Map<String, Object>{ 
        'registration_data' => dummyInResponseWrap
    };

     /****************************************************************************************************************
    * @Function - callout
    * @param caseRec - Case record from the framework.
    * @return - void
    * @Description - Called for Different APIs =>BRE_Foreclosure_Retail,BRE_BalanceConfirmation_Retail,BRE_ClosureProcess_Retail
    * BRE_Foreclosure_Retail,BRE_NDCReasonMaster_Retail, BRE_RepaymentSchedule_Retail, BRE_WelcomeLetter_Retail
    *****************************************************************************************************************/
    public static void fireENachRegistrationAPI(){//ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg
        System.debug('In fireENachRegistrationAPI:');     
        // publish event
        Database.SaveResult publishResult = EventBus.publish(
            new Case_Integration_Outbound__e (
                Business_Unit__c  = 'ABFL',//caseRecord.Business_Unit__c
                Case_Integration_ID__c = 'ASF_CInt_0001',//caseIntg[0]?.Name
                Integration_Name__c  = 'eNachRegistration', //integRec.STP_API_Identifier__c // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  ABCL_Encryption.encrypt(JSON.serialize(dummyResponseWrap))
            )
        );
    }
}
// Request:
// {
//     'enach_data'=>{
//         'pl_merchant_id'=>'MRC8821',
//         'customer_Id'=>'7406498698',
//         'customer_mobile_no'=>'7498791441',
//         'customer_name'=>'Vaibhav',
//         'customer_email_id'=>'guest@phicommerce.com',
//         'customer_bank_ifsc'=>'UTIB0000305',
//         'customer_bank_acc_no'=>'921010038015673',
//         'amount'=>'10.00',
//         'start_date'=>'20240224',
//         'end_date'=>'20240816',
//         'frequency'=>'V',
//         'debit_type'=>'MAXAMOUNT',
//         'return_url'=>'http://localhost:8090/resultpage'
//     }
// }

// Response: 
// {
//     "registration_data": {
//         "pl_enach_id": "7406498698",
//         "created_date": "20240205",
//         "registration_link":
//         "https://paymentloungeuat.adityabirlacapital.com/pg/portal/pay/enachRequest?requestID=7406498698&actionType=viewRequest&merchantid=T_88821",
//          "return_code": "0000",
//         "resp_description": "Request Processed Successfully"
//     }
//  }