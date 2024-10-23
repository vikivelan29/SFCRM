/***************************************************************************
*Class          :  RNWL_NonIndAccountRenewalController
*Author         :  Gaurav Sharma
*Created Date   :  13/09/2024
*Last Modified  :  13/09/2024
*@description   :  This class is used to get the Renewal Policy Details for 
                   Non-Individual Account type
****************************************************************************/
//Making the class without sharing because end user context will update the record.
public without sharing class RNWL_NonIndAccountRenewalController {
    
    @AuraEnabled
    public static Policy_Detail_Wrapper getRenewalDetails_NonIndAcc(String opportunityId){
        try {
			List<Opportunity> oppList = [SELECT Id,Policy_Number__c, Premium_Amount__c,
                                                Proposal_Number__c
                                         FROM Opportunity 
                                         WHERE Id=:opportunityId 
                                         LIMIT 1];
            
            String policyNumber = oppList[0].Policy_Number__c;
			String responseBody = getResponseFromFiles(opportunityId , 'Renewal Group Check');
            Policy_Detail_Wrapper details = new Policy_Detail_Wrapper();

            if(String.isBlank(responseBody)){
                String payload = '{"lead_Id":null,"master_policy_number":null,"certificate_number":"' + policyNumber + '","dob":"","proposer_mobileNumber":""}';
                
                ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABCL_IntegrationCallout.executeCallout('RNWL_Non_Ind_Account', payload, null);
                String fileName = 'Renewal Group Check-'+Date.today();
                system.debug(responseWrapper);
                responseBody = responseWrapper.responseBody;
                if(String.isNotBlank(responseBody)){
                    uploadFileToOpportunity(oppList[0].Id , responseBody , fileName , 'Renewal Group Check');
                }else{
                    details.hasError = true;
                    details.errorMessage = 'API Call Failed Please Retry'; 
                    return details;
                }
            }
            
            ResponseBodyWrapper respWrapper = (ResponseBodyWrapper)JSON.deserialize(responseBody, ResponseBodyWrapper.class);
            
            if(respWrapper.error != null && respWrapper.error[0].ErrorCode != '00' 
                && respWrapper.error[0].ErrorMessage != 'Success'){
                    details.hasError = true;
                    details.errorMessage = respWrapper.error[0].ErrorMessage; 
                    return details;
            }

            List<Policy_Details> policyDetails      = new List<Policy_Details>();
            List<Premium_Details> premiumDetails    = new List<Premium_Details>();
            List<Member_Details> memberDetails      = new List<Member_Details>();
            List<Nominee_Details> nomineeDetails    = new List<Nominee_Details>();
            List<Renewal_Info> renewalInfos         = new List<Renewal_Info>();
            List<Combi_Policy_Details> combiDetails = new List<Combi_Policy_Details>();

            String masterPolicyNumber;
            Boolean combiFlag = false;

            Set<String> memberCodes = new Set<String>();

            for(cls_policyData data: respWrapper.response.policyData){
                if(data.Certificate_number != null && data.certificate_number == policyNumber){
                    Policy_Details plcDetail = (Policy_Details)JSON.deserialize((JSON.serialize(data)) , Policy_Details.class);
                    policyDetails.add(plcDetail);

                    Premium_Details premiumDetail = (Premium_Details)JSON.deserialize((JSON.serialize(data.premium)) , Premium_Details.class);
                    premiumDetail.Certificate_number = data.Certificate_number;
                    premiumDetails.add(premiumDetail);

                    for(cls_Members member : data.Members){
                        Member_Details memberDetail = (Member_Details)JSON.deserialize((JSON.serialize(member)) , Member_Details.class);
                        memberDetail.Certificate_number = data.Certificate_number;
                        memberDetail.SumInsured         = member.MemberproductComponents[0]?.SumInsured;
                        memberDetail.NetPremium         = member.MemberproductComponents[0]?.NetPremium;
                        memberDetail.NetPremium_U       = member.MemberproductComponents[0]?.NetPremium_U;
                        memberDetail.CB                 = member.MemberproductComponents[0]?.CB;
                        memberDetail.Hr_Amount          = member.MemberproductComponents[0]?.Hr_Amount;
                        memberDetail.Member_Code        = member.Member_Code;
                        memberDetails.add(memberDetail);
                        if(String.isNotBlank(memberDetail.Member_Code)){
                            memberCodes.add(memberDetail.Member_Code);
                        }
                    }
                
                    Nominee_Details nomineeDetail = (Nominee_Details)JSON.deserialize((JSON.serialize(data.Nominee_Details)) , Nominee_Details.class);
                    nomineeDetail.Certificate_number = data.Certificate_number;
                    nomineeDetails.add(nomineeDetail);

                    masterPolicyNumber = data?.MaterPolicyNumber;

                    if(String.isNotBlank(data.Combi_Flag) &&  Integer.valueof(data.Combi_Flag) > 0){
                        combiFlag = true;
                    }
                }
            }

            String renewedProposalNumber;
            Set<String> renewdMasterPolicyNumbers = new Set<String>();

            for(cls_Renew_Info data: respWrapper.Renew_Info){
                if(data.Renewed_MaterPolicy_Number != null && data.Renewed_MaterPolicy_Number == masterPolicyNumber){
                    Renewal_Info renewalDetail = (Renewal_Info)JSON.deserialize((JSON.serialize(data)) , Renewal_Info.class);
                    renewalInfos.add(renewalDetail);
					renewedProposalNumber = data?.Renewed_Policy_Proposal_Number;
                }else if(combiFlag && data.Renewed_MaterPolicy_Number != masterPolicyNumber){
                    renewdMasterPolicyNumbers.add(data.Renewed_MaterPolicy_Number);
                }
            }

            if(renewdMasterPolicyNumbers.size() > 0 ){
                List<Asset> assets = [SELECT id,Account.Name , 
                                                Issue_Date__c, 
                                                Maturity_Date__c, 
                                                Status, 
                                                Cover_Type__c, 
                                                ProductName__c, 
                                                Plan_Name__c,
                                                MasterPolicyNumber__c, 
                                                MasterPolicyNumber__r.name
                                        FROM Asset 
                                        WHERE Name IN:renewdMasterPolicyNumbers];
                for(Asset ast : assets){
                    Combi_Policy_Details combiDetail = new Combi_Policy_Details();
                    combiDetail.combi_Policy_Number      = ast.MasterPolicyNumber__r?.name;
                    combiDetail.combi_Policy_Owner       = ast.Account?.name;
                    combiDetail.combi_Policy_StartDate   = ast.Issue_Date__c?.format();
                    combiDetail.combi_Policy_EndDate     = ast.Maturity_Date__c?.format();
                    combiDetail.combi_Policy_Status      = ast.Status;
                    combiDetail.combi_Policy_Variant     = ast.Cover_Type__c;
                    combiDetail.combi_Policy_Product     = ast.ProductName__c;
                    combiDetail.combi_Policy_SubPlan     = ast.Plan_Name__c;
                    combiDetail.combi_Policy_ProductType = ast.ProductName__c;
                    
                    combiDetails.add(combiDetail);
                }                        
            }

            if(memberCodes.size() > 0 ){
                List<Account> accList = [SELECT Id,Chronic_Disease__c,PED__c,Client_Code__c
                                         FROM Account 
                                         WHERE Client_Code__c IN :memberCodes];
                Map<String,Account> clientCodeToAcc = new Map<String,Account>();

                for(Account acc : accList){
                    clientCodeToAcc.put(acc.Client_Code__c , acc);
                }
                
                for(Member_Details memberDetail : memberDetails){
                    if(clientCodeToAcc.containsKey(memberDetail.Member_Code)){
                        memberDetail.Chronic_Disease = clientCodeToAcc.get(memberDetail.Member_Code).Chronic_Disease__c;
                        memberDetail.Disease_Disclose = clientCodeToAcc.get(memberDetail.Member_Code).PED__c;
                    }
                }
            }

            details.policyDetails   = policyDetails;
            details.premiumDetails  = premiumDetails;
            details.memberDetails   = memberDetails;
            details.nomineeDetails  = nomineeDetails;
            details.renewalInfos    = renewalInfos;
            details.combiDetails    = combiDetails;
            details.hasError        = false;
            details.errorMessage    = null;
			 
            Boolean isUpdatedNeeded = false;
            
            if(!premiumDetails.isEmpty() && oppList[0].Premium_Amount__c != Decimal.valueOf(premiumDetails[0].Renewal_Gross_Premium)){
                oppList[0].Premium_Amount__c = Decimal.valueOf(premiumDetails[0].Renewal_Gross_Premium);
                isUpdatedNeeded = true;
            }
            
            if(String.isNotBlank(renewedProposalNumber) && oppList[0].Proposal_Number__c != renewedProposalNumber){
                oppList[0].Proposal_Number__c = renewedProposalNumber;  
                isUpdatedNeeded = true;
            }
            
            if(isUpdatedNeeded){
                update oppList[0];
            }
            
            return details;
        } catch (Exception e) {
            system.debug(e.getMessage());
            system.debug(e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getResponseFromFiles(String opportunityId , String fileSourceAPI){
        List<ContentDocumentLink> cdlinks = [SELECT ContentDocumentId, LinkedEntityId 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId =:opportunityId 
                                            AND LinkedEntity.Type='Opportunity'];
        
        Set<Id> documentIds = new Set<Id>();    
        for(ContentDocumentLink cd : cdlinks){
            documentIds.add(cd.ContentDocumentId);
        }    

        if(documentIds.size() > 0){
            List<ContentVersion> cvList = [SELECT Id ,Content_Source_API__c, VersionData
                                           FROM ContentVersion 
                                           WHERE CreatedDate = TODAY
                                           AND ContentDocumentId IN: documentIds
                                           AND Content_Source_API__c =:fileSourceAPI ];
            if(cvList != null && cvList.size() > 0){
                return cvList[0]?.VersionData?.toString();
            }
        }
        return null;                                   
    }

    public static void uploadFileToOpportunity(Id opportunityId, String fileBody, String fileName, String fileSourceAPI) {
        Blob fileBodyBlob = Blob.valueof(fileBody);
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = fileName;
        contentVersion.VersionData = fileBodyBlob;
        contentVersion.Content_Source_API__c = fileSourceAPI;
        insert contentVersion;

		contentVersion = [Select Id,ContentDocumentId From ContentVersion Where id=:contentVersion.Id LIMIT 1];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = opportunityId;
        contentDocumentLink.ShareType = 'V'; // V = Viewer
        insert contentDocumentLink;

    }

    class ResponseBodyWrapper{
        public cls_error[] error;
        public cls_response response;
        public cls_Renew_Info[] Renew_Info;
    }
    class cls_error {
        public String ErrorCode;
        public String ErrorMessage;
    }
    class cls_response {
        public cls_policyData[] policyData;
    }
    class cls_policyData {
        public cls_PolicyproductComponents[] PolicyproductComponents;
        public String MaterPolicyNumber;
        public String Certificate_number;
        public String Sum_insured_type;
        public String Policy_start_date;
        public String Policy_renewal_date;
        public String Policy_expiry_date;
        public String Policy_lapsed_flag;
        public String Upsell_Flag;
        public String Renewable_flag;
        public String Renewed_Flag;
        public String Combi_Flag;
        public cls_premium premium;
        public String Name_of_the_proposer;
        public cls_Members[] Members;
        public String Name_of_product;
        public String Auto_Debit;
        public cls_Nominee_Details Nominee_Details;
    }
    class cls_PolicyproductComponents {
        public String PlanCode;
        public String SchemeCode;
        public String NetPremium;
        public String NetPremium_U;
    }
    class cls_premium {
        public String Renewal_Net_Premium;
        public String Renewal_Gross_Premium;
        public String Upsell_Net_Premium;
        public String Upsell_Gross_Premium;
    }
    class cls_Members {
        public cls_MemberproductComponents[] MemberproductComponents;
        public String Name;
        public String Title;
        public String FirstName;
        public String LastName;
        public String Relationship_Code;
        public String GHDApplicable;
        public String GHDRemarks;
        public String Member_Code;
        public String DoB;
        public String Gender;
        public String Email;
        public String Mobile_Number;
        public String Relation;
    }
    class cls_MemberproductComponents {
        public String PlanCode;
        public String SumInsured;
        public String NetPremium;
        public String NetPremium_U;
        public String CB;
        public String Hr_Amount;
    }
    class cls_Nominee_Details {
        public String Nominee_Name;
        public String Nominee_Address;
        public String Nominee_Contact_No;
    }
    class cls_Renew_Info {
        public String Renewed_Certificate_Number;
        public String Renewed_MaterPolicy_Number;
        public String Renewed_Policy_Proposal_Number;
        public String Renewed_Policy_Start_Date;
        public String Renewed_Policy_Expiry_Date;
    }
    

    // Response wrappers as per sections on UI: 
    public class Policy_Detail_Wrapper{
        @AuraEnabled public Boolean hasError;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public List<Policy_Details> policyDetails;
        @AuraEnabled public List<Premium_Details> premiumDetails;
        @AuraEnabled public List<Member_Details> memberDetails;
        @AuraEnabled public List<Nominee_Details> nomineeDetails;
        @AuraEnabled public List<Renewal_Info> renewalInfos;
        @AuraEnabled public List<Combi_Policy_Details> combiDetails;
    }

    public class Policy_Details{
        @AuraEnabled public String MaterPolicyNumber;
        @AuraEnabled public String Certificate_number;
        @AuraEnabled public String Sum_insured_type;
        @AuraEnabled public String Policy_start_date;
        @AuraEnabled public String Policy_renewal_date;
        @AuraEnabled public String Policy_expiry_date;
        @AuraEnabled public String Policy_lapsed_flag;
        @AuraEnabled public String Upsell_Flag;
        @AuraEnabled public String Renewable_flag;
        @AuraEnabled public String Renewed_Flag;
        @AuraEnabled public String Combi_Flag;
        @AuraEnabled public String Name_of_the_proposer;
        @AuraEnabled public String Name_of_product; 
        @AuraEnabled public String Auto_Debit;
    }
    
    public class Premium_Details{
        @AuraEnabled public String Certificate_number;
        @AuraEnabled public String Upsell_Net_Premium;
        @AuraEnabled public String Upsell_Gross_Premium;
        @AuraEnabled public String Renewal_Net_Premium;
        @AuraEnabled public String Renewal_Gross_Premium;
    }

    public class Member_Details{
        @AuraEnabled public String Certificate_number;
        @AuraEnabled public String Name;
        @AuraEnabled public String DoB;
        @AuraEnabled public String Gender;
        @AuraEnabled public String Email;
        @AuraEnabled public String Mobile_Number;
        @AuraEnabled public String Relation;
        @AuraEnabled public String SumInsured;
        @AuraEnabled public String NetPremium;
        @AuraEnabled public String NetPremium_U;
        @AuraEnabled public String CB;
        @AuraEnabled public String Hr_Amount;
        @AuraEnabled public String Chronic_Disease;
        @AuraEnabled public String Disease_Disclose;
        public String Member_Code;
    }

    public class Nominee_Details{
        @AuraEnabled public String Certificate_number;
        @AuraEnabled public String Nominee_Name;
        @AuraEnabled public String Nominee_Address;
        @AuraEnabled public String Nominee_Contact_No;
    }
    public class Renewal_Info{
        @AuraEnabled public String Renewed_MaterPolicy_Number;
        @AuraEnabled public String Renewed_Certificate_Number;
        @AuraEnabled public String Renewed_Policy_Proposal_Number;
        @AuraEnabled public String Renewed_Policy_Start_Date;
        @AuraEnabled public String Renewed_Policy_Expiry_Date;
    }

    public class Combi_Policy_Details{
        @AuraEnabled public String combi_Policy_Number;
        @AuraEnabled public String combi_Policy_Owner;
        @AuraEnabled public String combi_Policy_StartDate;
        @AuraEnabled public String combi_Policy_EndDate;
        @AuraEnabled public String combi_Policy_Status;
        @AuraEnabled public String combi_Policy_Variant;
        @AuraEnabled public String combi_Policy_Product;
        @AuraEnabled public String combi_Policy_SubPlan;
        @AuraEnabled public String combi_Policy_ProductType;
    }
}