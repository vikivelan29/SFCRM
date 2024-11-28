public with sharing class ABFL_EnachRegistrationResponse {

    public class Enach_data {
        public String pl_enach_id;
        public String pl_merchant_id;
        public String customer_Id;
        public String customer_mobile_no;
        public String customer_email_id;
        public String customer_name;
        public String customer_bank_ifsc;
        public String customer_bank_acc_no;
        public String amount;
        public String start_date;
        public String end_date;
        public String debit_type;
        public String frequency;
        public String return_url;
        public String status;
        public String status_code;
    }
    
    public class Registration_data {
        public String pl_enach_id;
        public String created_date;
        public String registration_link;
        public String return_code;
        public String resp_description;
    }

    public Enach_data enach_data;
    public Registration_data registration_data;

    public static ABFL_EnachRegistrationResponse parse(String json) {
        return (ABFL_EnachRegistrationResponse) System.JSON.deserialize(json, ABFL_EnachRegistrationResponse.class);
    }
}