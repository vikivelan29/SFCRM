/*********************************************************
*Class        :  ABHFL_ComplaintInvestigationController
*Author       :  Aditya Mehrotra
*Created Date :  30/01/2024
*Last Modified:  30/01/2024
*Description  :  Controller class for Complaint Investigation API
*********************************************************/
public with sharing class ABHFL_ComplaintInvestigationController {

    public static String pdfHeader{get;set;}
    public static String pdfContent{get;set;}
    
    public ABHFL_ComplaintInvestigationController(){
        if (ApexPages.currentPage() != null && ApexPages.currentPage().getParameters() != null &&
           		!ApexPages.currentPage().getParameters().isEmpty()){
            pdfHeader=String.escapeSingleQuotes(
                ApexPages.currentPage().getParameters().get('pdfHeader'));
            pdfContent=String.escapeSingleQuotes(
                ApexPages.currentPage().getParameters().get('pdfContent'));
        }else{
            pdfHeader = '';
            pdfContent = '';
        }   
    }
    
    @AuraEnabled
    public static String generatePDF(String pdfHeaderValue,List<Object> pdfContentValue, String caseId){
        Case c = [SELECT Id, AccountId, ABHFL_Case_Detail__c FROM Case WHERE Id=:caseId LIMIT 1];

        List<ABHFL_Case_Detail__c> caseDetail = [SELECT Id, Current_cibil_score__c, FI_Report_R__c, FI_Report_O__c,
            Current_Report_RCU_R__c, Current_Report_RCU_O__c, Document_Verification_Remarks__c, Legal_report_at_onboarding__c,
            Current_Title_search_report__c, Valuation_technical_report_at_onboarding__c, Current_Valuation_Remark__c,
            OCR_Remark__c, Google_Search__c, Underwriting_Review__c, Lapses__c, Punitive_action__c, Case_Status__c,
            Applicant_profile_at_time_of_onboarding__c, Current_cibil_review__c,/*Complaint_Investigation_PDF_HTML__c,*/
            Credit_Deviation__c
            FROM ABHFL_Case_Detail__c
            WHERE Id=:c.ABHFL_Case_Detail__c];

        Account acc = [SELECT Id, PAN__c, PersonBirthdate, Full_Name__pc FROM Account WHERE Id=:c.AccountId LIMIT 1];

        List<ComplaintInvestigationWrapper> contentList = new List<ComplaintInvestigationWrapper>();
        for(Object obj:pdfContentValue){
            Map<Object,Object> objMap = (Map<Object,Object>)obj;
            contentList.add(new ComplaintInvestigationWrapper((String)objMap.get('label'), (String)objMap.get('fieldName'), objMap.get('value')));
        }
        contentList.add(new ComplaintInvestigationWrapper('Current cibil score', 'Current_cibil_score__c', caseDetail[0].Current_cibil_score__c!=null?String.valueOf(caseDetail[0].Current_cibil_score__c):''));
        contentList.add(new ComplaintInvestigationWrapper('Applicant profile at a time of onboarding', 'Applicant_profile_at_time_of_onboarding__c', caseDetail[0].Applicant_profile_at_time_of_onboarding__c!=null?caseDetail[0].Applicant_profile_at_time_of_onboarding__c:''));
        contentList.add(new ComplaintInvestigationWrapper('Credit Deviation', 'Credit_Deviation__c', caseDetail[0].Credit_Deviation__c!=null?caseDetail[0].Credit_Deviation__c:''));
        contentList.add(new ComplaintInvestigationWrapper('Current cibil review', 'Current_cibil_review__c', caseDetail[0].Current_cibil_review__c!=null?caseDetail[0].Current_cibil_review__c:''));
       
        pdfContent = ABHFL_ComplaintInvestigationController.constructHTML(contentList, caseDetail[0]);
        
        //Blob strPdfBody = null;
        Pagereference pg = Page.ABHFL_ComplaintInvestigationPDF;
        pg.getParameters().put('pdfHeader', pdfHeaderValue);
        pg.getParameters().put('pdfContent', pdfContent);
        pg.getHeaders().put('content-disposition', 'inline; filename=Complaint_Investigation.pdf');
        /*caseDetail[0].Complaint_Investigation_PDF_HTML__c = pdfContent;
        update caseDetail[0];*/
        //strPdfBody =  pg.getContent();
        /*Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + thePage.getUrl());
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer '+UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setBody('customFormData='+customFormData);*/
        /*ContentVersion objVersion = new ContentVersion();
        objVersion.ContentLocation = 'S';
        objVersion.PathOnClient = 'Test ' +ast.Name +'.pdf';
        objVersion.Title = 'Test ' +ast.Name;
        objVersion.VersionData = strPdfBody;
        insert objVersion;
        
        Id objDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:objVersion.Id].ContentDocumentId;
        ContentDocumentLink objDocumentLink = New ContentDocumentLink();
        objDocumentLink.LinkedEntityId = ast.Id;
        objDocumentLink.ContentDocumentId = objDocId;
        objDocumentLink.shareType = 'V';
        insert objDocumentLink;*/
            
        return '?pdfHeader='+pdfHeaderValue+'&pdfContent='+pdfContent;
    }
    
    public static String constructHTML(List<ComplaintInvestigationWrapper> wrapList,ABHFL_Case_Detail__c caseDetail){
        String htmlString = '<table border="1">';
        for (ComplaintInvestigationWrapper row : wrapList) {
            htmlString += '<tr>';
                htmlString += '<td style="color:blue">' + row.label + '</td>';
                htmlString += '<td>' + row.value + '</td>';
            htmlString += '</tr>';
        }
            htmlString += '<tr>';
                htmlString += '<td style="color:blue">' + 'Profile Verification Remarks' + '</td>';
                htmlString += '<td>';
                    htmlString += '<table border="1">';
                        htmlString += '<tr>';
                            htmlString += '<td></td>';
                            htmlString += '<td>'+'Fi reports at a time of onboarding'+'</td>';
                            htmlString += '<td>'+'Current visit report by RCU'+'</td>';
                        htmlString += '</tr>';
                        htmlString += '<tr>';
                            htmlString += '<td>'+'Residence'+'</td>';
                            htmlString += '<td>'+caseDetail.FI_Report_R__c+'</td>';
                            htmlString += '<td>'+caseDetail.Current_Report_RCU_R__c+'</td>';
                        htmlString += '</tr>';
                        htmlString += '<tr>';
                            htmlString += '<td>'+'Office'+'</td>';
                            htmlString += '<td>'+caseDetail.FI_Report_O__c+'</td>';
                            htmlString += '<td>'+caseDetail.Current_Report_RCU_O__c+'</td>';
                        htmlString += '</tr>';
                    htmlString += '</table>';
                htmlString += '</td>';
            htmlString += '</tr>';

            htmlString += '</tr>';
                htmlString += '<td style="color:blue">'+'Document Verification Remarks'+'</td>';
                htmlString += '<td>'+caseDetail.Document_Verification_Remarks__c+'</td>';
            htmlString += '<tr>';

            htmlString += '<tr>';
                htmlString += '<td style="color:blue">' + 'Legal check' + '</td>';
                htmlString += '<td>';
                    htmlString += '<table border="1">';
                        htmlString += '<tr>';
                            htmlString += '<td>'+'Legal reports at a time ofonboarding'+'</td>';
                            htmlString += '<td>'+'Current Title search report'+'</td>';
                        htmlString += '</tr>';
                        htmlString += '<tr>';
                            htmlString += '<td>'+caseDetail.Legal_report_at_onboarding__c+'</td>';
                            htmlString += '<td>'+caseDetail.Current_Title_search_report__c+'</td>';
                        htmlString += '</tr>';
                    htmlString += '</table>';
                htmlString += '</td>';
            htmlString += '</tr>';

            htmlString += '<tr>';
                htmlString += '<td style="color:blue">' + 'Valuation, technical check, and property visit remark' + '</td>';
                htmlString += '<td>';
                    htmlString += '<table border="1">';
                        htmlString += '<tr>';
                            htmlString += '<td>'+'Valuation and technical reports at time of onboarding'+'</td>';
                            htmlString += '<td>'+'Current Valuation remark'+'</td>';
                        htmlString += '</tr>';
                        htmlString += '<tr>';
                            htmlString += '<td>'+caseDetail.Valuation_technical_report_at_onboarding__c+'</td>';
                            htmlString += '<td>'+caseDetail.Current_Valuation_Remark__c+'</td>';
                        htmlString += '</tr>';
                    htmlString += '</table>';
                htmlString += '</td>';
            htmlString += '</tr>';

            htmlString += '<tr>';
                htmlString += '<td style="color:blue">'+'OCR Remark'+'</td>';
                htmlString += '<td>'+caseDetail.OCR_Remark__c+'</td>';
            htmlString += '</tr>';
            
            htmlString += '<tr>';
                htmlString += '<td style="color:blue">'+'Google Search'+'</td>';
                htmlString += '<td>'+caseDetail.Google_Search__c+'</td>';
            htmlString += '</tr>';
            
            htmlString += '<tr>';
                htmlString += '<td style="color:blue">'+'Underwriting Review'+'</td>';
                htmlString += '<td>'+caseDetail.Underwriting_Review__c+'</td>';
            htmlString += '</tr>';

            htmlString += '<tr>';
                htmlString += '<td style="color:blue">'+'Lapses'+'</td>';
                htmlString += '<td>'+caseDetail.Lapses__c+'</td>';
            htmlString += '</tr>';

            htmlString += '<tr>';
                htmlString += '<td style="color:blue">'+'Punitive action'+'</td>';
                htmlString += '<td>'+caseDetail.Punitive_action__c+'</td>';
            htmlString += '</tr>';

        htmlString += '</table>';
        return htmlString;
    }

    @AuraEnabled(cacheable=true)
    public static List<ComplaintInvestigationWrapper> fetchDetails(String caseId){
        Case c= [SELECT Id, AccountId, Asset.LAN__c FROM Case WHERE Id=:caseId LIMIT 1];
        Account acc = [SELECT Id, PAN__c, PersonBirthdate, Full_Name__pc, BillingAddress FROM Account WHERE Id=:c.AccountId LIMIT 1];

        String requestBody = JSON.serialize(new ComplaintInvestigationRequestWrapper(c.Asset.LAN__c));
        ABCL_IntegrationCallout.IntegrationResponseWrapper response = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.COMPLAINT_INVESTIGATION_INTEGRATION_METADATA,requestBody,null);
        ComplaintInvestigationResponseWrapper responseWrapper = new ComplaintInvestigationResponseWrapper();
        if(response.statusCode == 200 && String.isNotBlank(response.responseBody)){
            responseWrapper = (ComplaintInvestigationResponseWrapper)JSON.deserialize(response.responseBody,ComplaintInvestigationResponseWrapper.class);
        }
        List<String> fieldList = Label.ABHFL_Complaint_Investigation_Details.split(',');
        ResponseClass responseCls = new ResponseClass();
        if(responseWrapper.success==true){
            responseCls = responseWrapper.result[0];
        }
        List<ComplaintInvestigationWrapper> wrapperList = new List<ComplaintInvestigationWrapper>();
        Map<String, Object> fieldMap = new Map<String, Object>();
        fieldMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(responseCls));

        for(String field: fieldList){
            if(field.split(':')[0]=='Customer Name'){
                ComplaintInvestigationWrapper wrapper = new ComplaintInvestigationWrapper(field.split(':')[0],field.split(':')[1],acc.Full_Name__pc!=null?acc.Full_Name__pc:'');
                wrapperList.add(wrapper);
            }
            if(field.split(':')[0]=='PAN No'){
                ComplaintInvestigationWrapper wrapper = new ComplaintInvestigationWrapper(field.split(':')[0],field.split(':')[1],acc.PAN__c!=null?acc.PAN__c:'');
                wrapperList.add(wrapper);
            }
            if(field.split(':')[0]=='DOB'){
                ComplaintInvestigationWrapper wrapper = new ComplaintInvestigationWrapper(field.split(':')[0],field.split(':')[1],acc.PersonBirthdate!=null?String.valueOf(acc.PersonBirthdate):'');
                wrapperList.add(wrapper);
            }
            if(field.split(':')[0]=='Type of transaction'){
                ComplaintInvestigationWrapper wrapper = new ComplaintInvestigationWrapper(field.split(':')[0],field.split(':')[1],fieldMap.get('DEAL_SCHEME')+' '+fieldMap.get('sub_scheme'));
                wrapperList.add(wrapper);
            }
            if(field.split(':')[0]=='Product and Segment'){
                ComplaintInvestigationWrapper wrapper = new ComplaintInvestigationWrapper(field.split(':')[0],field.split(':')[1],fieldMap.get('Product')+' '+fieldMap.get('CATEGORY'));
                wrapperList.add(wrapper);
            }
            if(field.split(':')[0]=='Residence address'){
                ComplaintInvestigationWrapper wrapper = new ComplaintInvestigationWrapper(field.split(':')[0],field.split(':')[1],acc.BillingAddress);
                wrapperList.add(wrapper);
            }
            if(field.split(':')[0]=='Credit authority'){
                ComplaintInvestigationWrapper wrapper = new ComplaintInvestigationWrapper(field.split(':')[0],field.split(':')[1],fieldMap.get('APPROVAL_BY')+' '+fieldMap.get('APPROVAL_BY_name'));
                wrapperList.add(wrapper);
            }
            if(fieldMap.containsKey(field.split(':')[1])){
                ComplaintInvestigationWrapper wrapper = new ComplaintInvestigationWrapper(field.split(':')[0],field.split(':')[1],fieldMap.get(field.split(':')[1])!=null?fieldMap.get(field.split(':')[1]):'');
                wrapperList.add(wrapper);
            }
        }
        if(wrapperList!=null){
            return wrapperList;
        }else{
            return null;
        }
    }

    public class ComplaintInvestigationWrapper{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public Object value;
        public ComplaintInvestigationWrapper(String l, String f, Object v){
            this.label = l;
            this.fieldName = f;
            this.value = v;
        }
    }

    public class ComplaintInvestigationRequestWrapper{
        public String loan_account_number;
        public ComplaintInvestigationRequestWrapper(String lan){
            this.loan_account_number = lan;
        }
    }

    public class ComplaintInvestigationResponseWrapper{
        public Boolean success;
        public ResponseClass[] result;
        public String message;
    }

    public class ResponseClass{
        public String Account_Status;
        public String Application_Number;
        public Decimal Approved_Limit;
        public String Created_On;
        public Decimal Current_rate_of_interest;
        public Decimal Avaliable_Limit;
        public String Interest_Basis;
        public String InterestRateType;
        public String Loan_Account_No;
        public Decimal Loan_amount;
        public String Loan_Start_Date;
        public String Modified_On;
        public String NPA_Status;
        public String Product;
        public Integer Tenor;
        public String RM_CODE;
        public String BUSINESS_LOB;
        public String Customer_No;
        public String Branchcode;
        public String Core_Created_On;
        public String Core_Modified_On;
        public String LEAD_ID;
        public String Last_Disbursement_Date;
        public Decimal Last_Disbursement_Amount;
        public Decimal Principal_Outstanding;
        public Decimal login_loan_amount;
        public String file_login_date;
        public String DEAL_APPLICATION_FORM_NO;
        public Integer link_customer_id;
        public String CATEGORY;
        public Decimal LOAN_EMI_AMOUNT;
        public Integer LOAN_DUE_DAY;
        public String DISBURSAL_STATUS;
        public Integer LOAN_ID;
        public String Deal_No;
        public Decimal Current_POS;
        public String DPD;
        public String DSA_Referral_partner;
        public String Credit_Eligibility_program;
        public String deal_ro;
        public String SO_Name;
        public String deal_rm;
        public String SM_Name;
        public Decimal deal_sanction_amount;
        public String DEAL_SCHEME;
        public String sub_scheme;
        public String LOAN_TYPE;
        public String Login_Date;
        public String Old_cibil_score;
        public String Score;
        public String COMPANY_NAME;
        public String comp_address;
        public String APPROVAL_BY;
        public String APPROVAL_BY_name;
        public Integer asset_id;
        public Decimal Valuation_as_per_system;
        public String PLOT_NO;
        public String FLOOR_NO;
        public String PROPERTY_ADDRESS;
        public String ADDRESS_LINE2;
        public String ADDRESS_LINE3;
        public String PINCODE;
        public Integer COUNTRY;
        public String DISTRICT_DESC;
        public String STATE_DESC;
        public String TEHSIL;
        public String Landmark;
        public Decimal Total_disbursed_amount;
        public Integer rn;
    }

}