public without sharing class ONEABC_Constants {
    
    public static string ONE_ABC_CUSTOMER_SEARCH_BY_ACCOUNTHOLDING = 'ONEABC_CUST_SEARCH_BY_ACCHOLD';
    public static string ONEABC_LOB_HOLDINGS = 'ONEABC_LOB_HOLDINGS';
    public static string ONE_ABC_LOB_CUSTOMERS = 'ONEABC_LOB_CUSTOMERS'; 
    public static Map<String,String> ASSET_HOLDING_FIELD_DETAILS = new Map<String,String>{'maskedAccountNo'=> 'Masked Account #',
        'consentStatus'=>'Consent Status','ifscCode'=>'IFSC Code','consentDate'=>'Consent Date','address' =>'Address',
        'branchName'=>'Branch Name','accountNo'=> 'Account #','bankName'=>'Bank Name','totalFDHoldings'=>'Total FD Holdings',
        'lastTransactionValue'=>'Last Transaction Value','bankName'=>'Bank Name','lastTransactionInterest'=>'Last Transaction Interest',
        'lastTransactionDate'=>'Last Transaction Date','mfDetails'=>'Mutual Fund','dgDetails'=>'Digi Gold','dsDetails'=>'Deposit',
        'dmDeatils'=>'Demat Details','pcDetails'=>'Porfolio Consolidation','leadConverted'=>'Lead Converted','accountOpeningDate'=>'Account Opening Date',
        'ekycStatus'=>'eKYC Status','portfolioBalance'=>'Portfolio Balance','lastTransactionType'=>'Last Transaction Type','lastTransactionQuantity'=>'Last Transaction Quantity',
        'lastTransactionDeliveryDate'=>'Last Transaction Delivery Date','plDetails' =>'Personal Loan Details','hflDetails'=>'Housing Finance Loan Details',
        'blDetails'=>'Business Loan Details','addresss'=>'Address','miDetails'=>'ACKO, Digit and ICICI - Details','liDetails'=>'Life Insurance Details','accountNumber'=>'Account Number',
        'dheDetails'=>'Digital Health Assessment','csDetails'=>'Credit Score','loyaltyRewards'=>'Loyalty Rewards','totalLoyaltyPoints'=>'Total Loyalty Points',
        'lastLoyaltyCreditPoints'=>'Last Loyalty Credit Points','lastLoyaltyCreditTransaction'=>'Last Loyalty Credit Transaction',
        'lastLoyaltyCreditDate'=>'Last Loyalty Credit Date','lastScanDate'=>'Last Scan Date','dheDataId'=>'DHE Data Id','lastdownloadDate'=>'Last Download Date',
        'customerId'=>'Customer Id'};
    public static string REQUEST_NATURE = 'Request'; 
    public static string COMPLAINT_NATURE = 'Complaint';
    public static string ONEABC_BU = 'ONEABC';

}