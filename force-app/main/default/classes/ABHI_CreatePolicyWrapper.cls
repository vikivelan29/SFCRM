/*********************************************************
*Class        :  ABHIL_CreatePolicy
*Author       :  Aditee Churiwala
*Created Date :  06/31/2024
*Last Modified:  06/31/2024
*@description :  Create policy wrapper
*********************************************************/
public with sharing class ABHI_CreatePolicyWrapper {
    
	public class Policy {
		public String AgentStatus;
		public String ARU;
		public String ActiveHealthVersion;
		public String ApplicationDate;
		public String ProposalNumber;
		public String AutoDebitFlag;
		public String AutoDebitRegistrationStatus;
		public String BalanceHR;
		public String BasicPremium;
		public String BusinessType;
		public String Channel;
		public String COILink;
		public String CountOfLives;
		public String CombiPolicyNo;
		public String CombiPolicyType;
		public String ConsumedHR;
		public String CrossSellNumber;
		public String DRMCustomer;
		public String DebitFrequency;
		public String DebitReason;
		public String Discount;
		public String FamilyType;
		public String FamilyDefinition;
		public String GoGreen;
		public String GrossPremium;
		public String HA;
		public String HHS;
		public String CustomerSegment;
		public String HR;
		public String IntermediaryCode;
		public String IntermediaryEmailId;
		public String IntermediaryMobileNumber;
		public String IntermediaryName;
		public String LeadId;
		public String MandateEndDate;
		public String MandateStartDate;
		public String MasterPolicy;
		public String MasterPolicyNumber;
		public String MaturityDate;
		public String Mode;
		public String NameOfEW;
		public String NetPremium;
		public String NextPremiumDate;
		public String OwnerClientCode;
		public String PaymentStatus;
		public String PlanName;
		public String PolicyCancellationReason;
		public String PolicyIssueDate;
		public String PolicyNumber;
		public String PolicyStatus;
		public String PolicySubStatus;
		public String PolicyTerm;
		public String PolicyType;
		public String PolicySubType;
		public String PortalCertificate;
		public String ProductName;
		public String ProposalType;
		public String RejectionReason;
		public String SNCB;
		public String SalesManagerEmail;
		public String SalesManagerMobile;
		public String SalesRelationshipManagerCode;
		public String SalesRelationshipManagerName;
		public String SandboxPolicy;
		public String ServicingBranchName;
		public String Source;
		public String TAXDetails;
		public String TPA;
		public String TPAContactDetails;
		public String TotalSumInsured;
		public String UR;
		public String UWLoading;
		public String ZoneOfCover;
		public String TotalHR;
		public String UtilizedHR;
		public String SponsoredFlag;
		public String RenewableFlag;
		public String PreviousPolicyNumber;
       // public String LAN;
	}

	public List<Customer> Customer;
	public List<CustomerMemberMapping> CustomerMemberMapping;
	public List<NomineeDetails> NomineeDetails;
	public Policy Policy;

	public class CustomerMemberMapping {
		public String ClientId;
		public String MemberId;
		public String MemberStatus;
        //External id field : name would be modified later
        public String ExternalId;
		public String MemberSubStatus;
		//public String PreExistingDiseaseWaitingPeriod;
		public String TotalNCB;
		public String RidersOpted;
		public String appdownloadstatus;
		public String SumInsured;
		public String UpfrontDiscount;
	}

	public class Customer {
		public String AadharNo;
		public String AddressLine1;
		public String AddressLine2;
		public String AddressLine3;
		public String AddressType;
		public String PIN;
		public String City;
		public String State;
		public String Email;
		public String HomePhone;
		public String Alternatemobile;
		public String CoreSystemId;
		public String CountryCode;
		public String DateofBirth;
		public String Designation;
		public String EmployeeCode;
		public String FirstName;
		public String FullName;
		public String Gender;
		public String LastName;
		public String HealthCardNumber;
		public String Height;
		public String Weight;
		public String MaritualStatus;
		public String MobilePhone;
		public String Nationality;
		public String Nationality1;
		public String PanNo;
		public String ParentCode;
		public String WhatsappNumber;
        public String HNICustomer;
        public String CEOClubAdvisor;
        public String PriorityCustomer;
        public String SensitiveCustomer;
        public String CustomerRoleType;
		/*public List<CustomerSegments> CustomerSegments;
		public List<CustomerRoles> CustomerRoles;*/
		public String EffectiveDate;
		public String InternationalNumber;
		public String MMICustomerID;
		public String Relation;
        public String BusinessUnit = 'ABHI';
	}

	public class CustomerSegments {
		public String Segment;
        //External id field : name would be modified later
        public String ExternalId;
	}

	public class NomineeDetails {
		public String Gender;
		public String NomineeContactNumber;
		public String NomineeDOB;
		public String NomineeName;
		public String NomineePercentage;
		public String Relationship;
        public String NomineeId;
	}

	public class CustomerRoles {
		public String CustomerType;
        //External id field : name would be modified later
        public String ExternalId;
	}
    
    public class ResponseWrapper {
		public String ProposalNumber { get; set; }
		public String StatusCode { get; set; }
        public String StatusMessage { get; set; }
        public String StatusRemarks { get; set; }
        public ResponseWrapper(String StatusCode, String StatusMessage, String StatusRemarks) {
            //this.ProposalNumber = ProposalNumber;
            this.StatusCode = StatusCode;
            this.StatusMessage = StatusMessage;
            this.StatusRemarks = StatusRemarks;
        }
    }
}