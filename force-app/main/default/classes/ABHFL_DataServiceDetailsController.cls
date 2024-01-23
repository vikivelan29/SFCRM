/*********************************************************
*Class        :  ABHFL_DataServiceDetailsController
*Author       :  Aditya Mehrotra
*Created Date :  09/01/2024
*Last Modified:  11/01/2024
*Description  :  Controller class for Data Service Details
*********************************************************/
public with sharing class ABHFL_DataServiceDetailsController {
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - executeDataServiceCallout
    * @return - A3SSummaryData.
    * @description - Invoked from the fetchAllSections function, this method executes the callout for fetching Data Service details.
    *****************************************************************************************************************/
    public static A3SSummaryData executeDataServiceCallout(){
        DataServiceRequestWrapper dataServiceRequest = new DataServiceRequestWrapper();
        String dataServiceRequestBody = JSON.serialize(dataServiceRequest);
        ABCL_IntegrationCallout.IntegrationResponseWrapper dataServiceResponse = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.DATASERVICE_INTEGRATION_METADATA,dataServiceRequestBody,null);
        A3SSummaryData dataServiceResponseWrapper = new A3SSummaryData() ;
        if(dataServiceResponse.statusCode == 200 && String.isNotBlank(dataServiceResponse.responseBody)){
            //String extractedData = ABHFL_SoapResponseParser.parseSoapResponse(dataServiceResponse.responseBody, 'data');
            //system.debug('Extracted Data:'+extractedData);
            dataServiceResponseWrapper = (A3SSummaryData)JSON.deserialize(dataServiceResponse.responseBody,A3SSummaryData.class);
        }
        system.debug('dataServiceResponseWrapper::'+dataServiceResponseWrapper);
        
        return dataServiceResponseWrapper;
    }
	
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - fetchAllSections
    * @return - List<DataServiceWrapper>.
    * @description - Invoked from the abhfl_dataServiceDetails lwc component, this method sends back a list of wrapper of response of Data service API
    *****************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<DataServiceWrapper> fetchAllSections(){
        
        A3SSummaryData dataServiceResponseWrapper = ABHFL_DataServiceDetailsController.executeDataServiceCallout();
        
        List<DataServiceWrapper> wrapperList = new List<DataServiceWrapper>();
        List<Data_Service_Details__mdt> dataServiceDetails = [SELECT Section_Fields__c, Type__c, Section_Label__c, Section_Name__c
                                                FROM Data_Service_Details__mdt];
        
        for(Data_Service_Details__mdt dataServiceSection : dataServiceDetails){
            DataServiceWrapper serviceWrapper = new DataServiceWrapper(dataServiceSection.Section_Name__c, dataServiceSection.Section_Label__c, dataServiceSection.Type__c);
            if(dataServiceSection.Section_Fields__c!=NULL){
                if(dataServiceSection.Section_Name__c =='applicationDetails'){
                    serviceWrapper.sectionFieldsMap.put('Application No',dataServiceResponseWrapper.Summary_Data[0].Loan_Status.rows[0].APPLICATION_NO);
                    //serviceWrapper.sectionFieldsMap.put('Created On',dataServiceResponseWrapper.Summary_Data[0].Loan_Status.rows[0].LAST_REPRICING); 
                    //serviceWrapper.sectionFieldsMap.put('LOB',dataServiceResponseWrapper.Summary_Data[0].Loan_Status.rows[0].RM_MOBILE); 
                    serviceWrapper.sectionFieldsMap.put('Loan Application Status',dataServiceResponseWrapper.Summary_Data[0].Loan_Status.rows[0].LOANSTATUS);
                    //serviceWrapper.sectionFieldsMap.put('Modified On',dataServiceResponseWrapper.Summary_Data[0].Loan_Status.rows[0].RM_MOBILE); 
                    //serviceWrapper.sectionFieldsMap.put('System',dataServiceResponseWrapper.Summary_Data[0].Loan_Status.rows[0].BRANCH_NAME);  
                }
                if(dataServiceSection.Section_Name__c =='disbursementDetails'){
                    //serviceWrapper.sectionFieldsMap.put('Created On',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_NAME);
                    serviceWrapper.sectionFieldsMap.put('Date of Disbursement',dataServiceResponseWrapper.Summary_Data[0].Disbursement_History.rows[0].DISBRUSMENT_DATE); 
                    serviceWrapper.sectionFieldsMap.put('Disbursed Amount',dataServiceResponseWrapper.Summary_Data[0].Disbursement_History.rows[0].AMOUNT); 
                    //serviceWrapper.sectionFieldsMap.put('Disbursement No',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].BRANCH_NAME);
                    //serviceWrapper.sectionFieldsMap.put('Disbursement Type',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_NAME);
                    //serviceWrapper.sectionFieldsMap.put('LOB',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_EMAIL); 
                    //serviceWrapper.sectionFieldsMap.put('Loan Account No',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_MOBILE); 
                    //serviceWrapper.sectionFieldsMap.put('Loan Schedule',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].BRANCH_NAME);
                    //serviceWrapper.sectionFieldsMap.put('Modified On',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_NAME);
                    //serviceWrapper.sectionFieldsMap.put('System',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_EMAIL); 
                }
                if(dataServiceSection.Section_Name__c =='repaymentDetails'){
                    //serviceWrapper.sectionFieldsMap.put('ECS Date',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_NAME);
                    //serviceWrapper.sectionFieldsMap.put('EMI Type',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_EMAIL); 
                    serviceWrapper.sectionFieldsMap.put('EMI Date',dataServiceResponseWrapper.Summary_Data[0].repayment_detail.rows[0].PREVIOUSEMI_DUEDATE); 
                    //serviceWrapper.sectionFieldsMap.put('LOB',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].BRANCH_NAME);  
                    serviceWrapper.sectionFieldsMap.put('Loan Account No',dataServiceResponseWrapper.Summary_Data[0].repayment_detail.rows[0].LOAN_ACCOUNT_NUMBER);
                    //serviceWrapper.sectionFieldsMap.put('Loan Schedule',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_EMAIL); 
                    //serviceWrapper.sectionFieldsMap.put('Pre EMI Type',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_MOBILE); 
                    //serviceWrapper.sectionFieldsMap.put('Pre Closure Charges',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].BRANCH_NAME);  
                    //serviceWrapper.sectionFieldsMap.put('Repayment No',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_NAME);
                    //serviceWrapper.sectionFieldsMap.put('System',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_EMAIL); 
                    serviceWrapper.sectionFieldsMap.put('Last Payment Made',dataServiceResponseWrapper.Summary_Data[0].repayment_detail.rows[0].PREVIOUSEMI_AMT); 
                    //serviceWrapper.sectionFieldsMap.put('Due Date',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].BRANCH_NAME);  
                    serviceWrapper.sectionFieldsMap.put('Overdue Days',dataServiceResponseWrapper.Summary_Data[0].account_detail.rows[0].DAYS_PAST_DUE);
                    //serviceWrapper.sectionFieldsMap.put('Repayment Date',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_EMAIL);
                }
                if(dataServiceSection.Section_Name__c == 'accountBalance'){
                    serviceWrapper.sectionFieldsMap.put('Current Overdue',dataServiceResponseWrapper.Summary_Data[0].account_detail.rows[0].AMOUNT_OVERDUE);
                    serviceWrapper.sectionFieldsMap.put('Int Pay for Current Month',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].INTEREST_RATE); 
                    //serviceWrapper.sectionFieldsMap.put('LOB',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_MOBILE); 
                    serviceWrapper.sectionFieldsMap.put('Loan Account No',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].LOAN_ACCOUNT_NUMBER);  
                    //serviceWrapper.sectionFieldsMap.put('Loan Schedule',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_NAME);
                    serviceWrapper.sectionFieldsMap.put('Outstanding Amount',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].LOAN_OUTSTANDING); 
                    //serviceWrapper.sectionFieldsMap.put('Penal Charges',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_MOBILE); 
                    //serviceWrapper.sectionFieldsMap.put('Principle O/S',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].BRANCH_NAME);
                    //serviceWrapper.sectionFieldsMap.put('System',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].BRANCH_NAME);
                }
                if(dataServiceSection.Section_Name__c =='ABFLContactInformation'){
                    serviceWrapper.sectionFieldsMap.put('RM NAME',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_NAME);
                    serviceWrapper.sectionFieldsMap.put('RM EMAIL',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_EMAIL); 
                    serviceWrapper.sectionFieldsMap.put('RM MOBILE',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].RM_MOBILE); 
                    serviceWrapper.sectionFieldsMap.put('BRANCH NAME',dataServiceResponseWrapper.Summary_Data[0].ABFL_Contact_Info.rows[0].BRANCH_NAME);  
                }
                if(dataServiceSection.Section_Name__c =='borrowerDetails'){
                    serviceWrapper.sectionFieldsMap.put('Borrower Name',dataServiceResponseWrapper.Summary_Data[0].borrower_detail.rows[0].BORROWER_NAME);
                    serviceWrapper.sectionFieldsMap.put('Co-borrower Name',dataServiceResponseWrapper.Summary_Data[0].borrower_detail.rows[0].CO_BORROWER_NAME); 
                    serviceWrapper.sectionFieldsMap.put('Borrower Correspondence Address',dataServiceResponseWrapper.Summary_Data[0].borrower_detail.rows[0].ADDRESS); 
                    serviceWrapper.sectionFieldsMap.put('Mobile',dataServiceResponseWrapper.Summary_Data[0].borrower_detail.rows[0].MOBILE);  
                    serviceWrapper.sectionFieldsMap.put('Phone Number',dataServiceResponseWrapper.Summary_Data[0].borrower_detail.rows[0].PHONE_NO);
                    serviceWrapper.sectionFieldsMap.put('Email',dataServiceResponseWrapper.Summary_Data[0].borrower_detail.rows[0].E_MAIL); 
                }
                if(dataServiceSection.Section_Name__c =='disbursementDetailsInner'){
                    serviceWrapper.sectionFieldsMap.put('Sanctioned Amount',dataServiceResponseWrapper.Summary_Data[0].Disbursement_summary.rows[0].TOTAL_SANCTION_AMT);
                    serviceWrapper.sectionFieldsMap.put('Disbursed Amount',dataServiceResponseWrapper.Summary_Data[0].Disbursement_summary.rows[0].CURRENT_DISB_AMT); 
                    serviceWrapper.sectionFieldsMap.put('Amount available for Disbursement',dataServiceResponseWrapper.Summary_Data[0].Disbursement_summary.rows[0].BALANCE_REMAINING); 
                    serviceWrapper.sectionFieldsMap.put('Last Disbursed Amount',dataServiceResponseWrapper.Summary_Data[0].Disbursement_summary.rows[0].AMOUNT_DISB_TILL_DATE);  
                }
                if(dataServiceSection.Section_Name__c =='loanContract'){
                    serviceWrapper.sectionFieldsMap.put('Interest Type',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].INTEREST_TYPE);
                    serviceWrapper.sectionFieldsMap.put('Interest Rate',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].INTEREST_RATE); 
                    serviceWrapper.sectionFieldsMap.put('Overdue Interest',dataServiceResponseWrapper.Summary_Data[0].Overdue_Charges.rows[0].INTEREST_OVERDUE); 
                    serviceWrapper.sectionFieldsMap.put('Interest Frequency',dataServiceResponseWrapper.Summary_Data[0].Loan_Status.rows[0].INTEREST_FREQUENCY);  
                }
                if(dataServiceSection.Section_Name__c =='loanDetails'){
                    serviceWrapper.sectionFieldsMap.put('Customer Id',dataServiceResponseWrapper.Summary_Data[0].account_detail.rows[0].CUSTOMER_NO);
                    serviceWrapper.sectionFieldsMap.put('Account No',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].ACCOUNT_NO); 
                    serviceWrapper.sectionFieldsMap.put('Product',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].PRODUCT); 
                    serviceWrapper.sectionFieldsMap.put('Primary Borrower',dataServiceResponseWrapper.Summary_Data[0].borrower_detail.rows[0].BORROWER_NAME);  
                    //serviceWrapper.sectionFieldsMap.put('Tenure End Date',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].INTEREST_TYPE);
                    serviceWrapper.sectionFieldsMap.put('Status',dataServiceResponseWrapper.Summary_Data[0].Loan_Status.rows[0].STATUS); 
                    serviceWrapper.sectionFieldsMap.put('Sanctioned Limit',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].SANCTION_LIMIT);  
                    serviceWrapper.sectionFieldsMap.put('Principle Outstanding',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].LOAN_OUTSTANDING);
                    serviceWrapper.sectionFieldsMap.put('Loan Maturity Date',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].LOAN_MATURITY_DATE); 
                    serviceWrapper.sectionFieldsMap.put('ECS Applicable',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].ECS_APPLICABLE); 
                    serviceWrapper.sectionFieldsMap.put('EMI',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].EMI_AMOUNT);  
                    //serviceWrapper.sectionFieldsMap.put('Tenure',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].INTEREST_TYPE);
                    serviceWrapper.sectionFieldsMap.put('Amount Due',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].AMOUNT_OVERDUE); 
                    serviceWrapper.sectionFieldsMap.put('Total Outstanding',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].OUTSTANDING_BALANCE); 
                    serviceWrapper.sectionFieldsMap.put('Amount Available for Disbursement',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].TOTAL_AMOUNT_DISBURSED);  
                    //serviceWrapper.sectionFieldsMap.put('Product Category',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].INTEREST_TYPE);
                    //serviceWrapper.sectionFieldsMap.put('Primary Account Holder',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].INTEREST_RATE); 
                    //serviceWrapper.sectionFieldsMap.put('Joint Holder Names',dataServiceResponseWrapper.Summary_Data[0].Overdue_Charges.rows[0].INTEREST_OVERDUE); 
                    serviceWrapper.sectionFieldsMap.put('Payment Frequency',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].REPAYMENT_FREQUENCY);  
                    serviceWrapper.sectionFieldsMap.put('Virtual Account Number',dataServiceResponseWrapper.Summary_Data[0].loan_info.rows[0].VIRTUAL_ACCOUNT_NO); 
                }
                if(dataServiceSection.Section_Name__c =='propertyDetails'){
                    serviceWrapper.sectionFieldsMap.put('Mortgaged Property Address',dataServiceResponseWrapper.Summary_Data[0].property_detail.rows[0].PROPERTYDETAILS);  
                    serviceWrapper.sectionFieldsMap.put('Property Type',dataServiceResponseWrapper.Summary_Data[0].property_detail.rows[0].PROPERTY_TYPE); 
                }
                if(dataServiceSection.Section_Name__c =='repaymentDetailsInnner'){
                    serviceWrapper.sectionFieldsMap.put('Bank Name',dataServiceResponseWrapper.Summary_Data[0].repayment_detail.rows[0].BANK_NAME);  
                    serviceWrapper.sectionFieldsMap.put('EMI Start Date',dataServiceResponseWrapper.Summary_Data[0].repayment_detail.rows[0].EMI_START_DATE); 
                    serviceWrapper.sectionFieldsMap.put('Account Number',dataServiceResponseWrapper.Summary_Data[0].repayment_detail.rows[0].ACCOUNT_NO);  
                    serviceWrapper.sectionFieldsMap.put('EMI End Date',dataServiceResponseWrapper.Summary_Data[0].repayment_detail.rows[0].EMI_END_DATE); 
                    serviceWrapper.sectionFieldsMap.put('EMI Amount',dataServiceResponseWrapper.Summary_Data[0].repayment_detail.rows[0].EMI_AMOUNT);  
                    serviceWrapper.sectionFieldsMap.put('Repayment Mode',dataServiceResponseWrapper.Summary_Data[0].repayment_detail.rows[0].REPAYMENT_MODE); 
                }
            }
            wrapperList.add(serviceWrapper);
        }
        return wrapperList;
    }
    
    public class DataServiceWrapper{
        @AuraEnabled
        public String sectionName;
        @AuraEnabled
        public String sectionLabel;
        @AuraEnabled
        public Map<String, String> sectionFieldsMap;
        @AuraEnabled
        public String type;
        
        public DataServiceWrapper(String secName, String secLabel, String tp){
            this.sectionName = secName;
            this.sectionLabel = secLabel;
            this.type = tp;
            this.sectionFieldsMap = new Map<String, String>();
        }
    }

    public class DataServiceRequestWrapper{

        public String CLIENT_CODE;
        public String LAN;

    }

    public class A3SSummaryData{
            public SummaryDatum[] Summary_Data;
    }

    public class SummaryDatum{

            public LoanInfo loan_info;
            public LoanStatus Loan_Status;
            public AccountdDetail account_detail;
            public BenificiaryDetail Benificiary_Details;
            public BorrowerDetail borrower_detail;
            public ABFLContactInfo ABFL_Contact_Info;
            public PropertyDetail property_detail;
            public RepaymentDetail repayment_detail;
            public EcsDetail ecs_detail;
            public AddressList Address_List;
            public DisbursementHistory Disbursement_History;
            public OverdueCharges Overdue_Charges;
            public DisbursementSummary Disbursement_summary;

    }

    public class LoanInfo{

            public Integer totalRows;
            //public Boolean moreRows;
            public LoanInfoRow[] rows;

    }

    public class LoanInfoRow{

            public string ACCOUNT_STATUS;
            public string AMOUNT_OVERDUE;
            public string INSTALLMENT_PLAN;
            public string INTEREST_TYPE;
            public string CYCLEDAY;
            public string FINAL_DISB_FLAG;
            public string TOTAL_TENOR;
            public string PEMI;
            public string LOAN_START_DATE;
            public string SANCTIONED_AMOUNT;
            public string NEXT_DUE_DATE;
            public string CURRENT_BALANCE;
            public string LOAN_ACCOUNT_NUMBER;
            public string REPAYMENT_FREQUENCY;
            public string LOAN_OUTSTANDING;
            public string ECS_APPLICABLE;
            public string ACCOUNT_NO;
            public string INSTALLMENT_NO;
            public string TOTAL_AMOUNT_DISBURSED;
            public string BUSINESS_DATE;
            public string PRODUCT;
            public string SANCTION_LIMIT;
            public string LAST_DISB_DATE;
            public string EMI_START_DATE;
            public string LOAN_MATURITY_DATE;
            public string EMI_END_DATE;
            public string REMAINING_TENURE;
            public string INTEREST_RATE;
            public string EMI_AMOUNT;
            public string OUTSTANDING_BALANCE;
			public String VIRTUAL_ACCOUNT_NO;
        
    }

    public class LoanStatus{

            public Integer totalRows;
            //public Boolean moreRows;
            public LoanStatusRow[] rows;

    }

    public class LoanStatusRow{

            public string APPLICATION_NO;
            public string PRODUCT;
            public string STATUS;
            public string RELATIONSHIP_MGR;
            public string ACCOUNT_TYPE;
            public string LAST_REPRICING;
            public string RESTRUCTURED;
            public string BOUNCE;
            public string PDD;
            public string NACH;
            public string LOANSTATUS;
            public string INTEREST_FREQUENCY;
            public string MOB;
            public string CONSTITUTION;
            public string FixedPeriod;
            public string BPLR;
            public string VAN;

    }

    public class AccountdDetail{

            public Integer totalRows;
            //public Boolean moreRows;
            public AccountdDetailRow[] rows;

    }

    public class AccountdDetailRow{

            public string MNAME;
            public string FNAME;
            public string ACCOUNT_STATUS;
            public string TOTAL_AMOUNT_DISBURSED;
            public string AMOUNT_OVERDUE;
            public string PRODUCT;
            public string LNAME;
            public string OUTSTANDING_AMOUNT;
            public string FINAL_DISB_FLAG;
            public string DAYS_PAST_DUE;
            public string CUSTOMER_NO;
            public string SANCTIONED_AMOUNT;
            public string LOAN_ACCOUNT_NUMBER;
            public string NEXT_DUE_AMOUNT;
            public string PORTFOLIO_CODE;
            public string LOAN_OUTSTANDING;

    }

    public class BenificiaryDetail{

            public Integer totalRows;
            //public Boolean moreRows;
            public BenificiaryDetailRow[] rows;

    }

    public class BenificiaryDetailRow{

            public String BANK;
            public String ACCOUNT_NO;
            public String IFSC_CODE;
            public String LOAN_ACCOUNT_NO;
            public String ACCOUNT_TYPE;
            public String BRANCH;

    }

    public class BorrowerDetail{

            public Integer totalRows;
            //public Boolean moreRows;
            public BorrowerDetailRow[] rows;

    }

    public class BorrowerDetailRow{

            public String PHONE_NO;
            public String MOBILE;
            public String BORROWER_NAME;
            public String ADDRESS;
            public String CO_BORROWER_NAME;
            public String E_MAIL;

    }

    public class ABFLContactInfo{

            public Integer totalRows;
            //public Boolean moreRows;
            public ABFLContactInfoRow[] rows;

    }

    public class ABFLContactInfoRow{

            public String BRANCH_NAME;
            public String SZINTERNAL_EMAIL;
            public String SZHOME_PHONE;
            public String RM_MOBILE;
            public String SZBUSINESS_UNIT_ID;
            public String RM_EMAIL;
            public String RM_NAME;

    }

    public class PropertyDetail{

            public Integer totalRows;
            //public Boolean moreRows;
            public PropertyDetailRow[] rows;

    }

    public class PropertyDetailRow{

            public String PROPERTY_TYPE;
            public String SZ_CUSTOMER_NO;
            public String LOAN_ACCOUNT_NO;
            public String PROPERTYDETAILS;
            public String PROPERTYSUB_TYPE;

    }

    public class RepaymentDetail{

            public Integer totalRows;
            //public Boolean moreRows;
            public RepaymentDetailRow[] rows;

    }

    public class RepaymentDetailRow{

            public String EMI_START_DATE;
            public String PREVIOUSEMI_AMT;
            public String EMI_END_DATE;
            public String ACCOUNT_NO;
            public String EMI_AMOUNT;
            public String REPAID_AMOUNT;
            public String CUSTOMER_NO;
            public String REPAYMENT_MODE;
            public String LOAN_ACCOUNT_NUMBER;
            public String BANK_NAME;
            public String PREVIOUSEMI_DUEDATE;

    }

    public class EcsDetail{

            public Integer totalRows;
            //public Boolean moreRows;
            public EcsDetailRow[] rows;

    }

    public class EcsDetailRow{

            public String BRANCH_NAME;
            public String MNAME;
            public String ECS_TILL;
            public String ACCOUNT_NO;
            public String FNAME;
            public String ECS_FROM;
            public String MICR_CODE;
            public String CUSTOMER_NO;
            public String LOAN_ACCOUNT_NUMBER;
            public String ACCOUNT_TYPE;
            public String LNAME;
            public String BANK_NAME;

    }

    public class AddressList{

            public Integer totalRows;
            //public Boolean moreRows;
            public AddressListRow[] rows;

    }

    public class AddressListRow{

            public String ADDRESS;
            public String ADDRESS_TYPE;

    }

    public class DisbursementHistory{

            public Integer totalRows;
            //public Boolean moreRows;
            public DisbursementHistoryRow[] rows;

    }

    public class DisbursementHistoryRow{

            public String BANK;
            public String ACCOUNT_NUMBER;
            public String AMOUNT;
            public String MODE_OF_DISB;
            public String ACCOUNT_TYPE;
            public String DISBRUSMENT_DATE;
            public String BENIFICIARY_NAME;
            public String BRANCH;

    }

    public class OverdueCharges{

            public Integer totalRows;
            //public Boolean moreRows;
            public OverdueChargesRow[] rows;

    }

    public class OverdueChargesRow{

            public String CHARGES;
            public String PRODUCT_NAME;
            public String LOAN_ACCOUNT_NO;
            public String INSURANCE_CHARGES_DUE;
            public String INTEREST_OVERDUE;
            public String ACCRUED_PANEL;
            public String TOTAL_OVERDUE_AMT;
            public String EXCESS_AMOUNT;
            public String PRINCIPAL_OVERDUE;

    }

    public class DisbursementSummary{

            public Integer totalRows;
            //public Boolean moreRows;
            public DisbursementSummaryRow[] rows;

    }

    public class DisbursementSummaryRow{

            public String CURRENT_DISB_AMT;
            public String AMOUNT_DISB_TILL_DATE;
            public String TOTAL_REFUNDABLE_AMOUNT;
            public String BALANCE_REMAINING;
            public String FINAL_DISB_FLAG;
            public String TOTAL_SANCTION_AMT;
            public String FEES_OUTSTANDING;
            public String MODE_OF_DISB;
            public String ACCOUNT_TYPE;

    }
    
}