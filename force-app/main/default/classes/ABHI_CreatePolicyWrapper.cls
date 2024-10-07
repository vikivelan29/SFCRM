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
		//public String ARU;
		//public String ActiveHealthVersion;
		//public String ApplicationDate;
		public String ProposalNumber;
		public String AutoDebitFlag;
		public String AutoDebitRegistrationStatus;
		//public String BalanceHR;
		public String BasicPremium;
		public String BusinessType;
		public String Channel;
		public String IsCombi;
		public String CountOfLives;
		public String CombiPolicyNo;
		public String CombiPolicyType;
		//public String ConsumedHR;
		public String CrossSellNumber;
		//public String DRMCustomer;
		//public String DebitFrequency;
		//public String DebitReason;
		public String Discount;
		public String FamilyType;
		public String FamilyDefinition;
		public String GoGreen;
		public String GrossPremium;
		//public String HA;
		//public String HHS;
		public String CustomerSegment;
		//public String HR;
		public String IntermediaryCode;
		public String IntermediaryEmailId;
		public String IntermediaryMobileNumber;
		public String IntermediaryName;
		public String LeadId;
		//public String MandateEndDate;
		//public String MandateStartDate;
		//public String MasterPolicy;
		public String MasterPolicyNumber;
		public String MaturityDate;
		public String Mode;
		//public String NameOfEW;
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
		//public String PortalCertificate;
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
		public String TotalSumInsured;
		public String UWLoading;
		public String ZoneOfCover;
		//public String TotalHR;
		public String SponsoredFlag;
		public String RenewableFlag;
		//public String PreviousPolicyNumber;
       // public String LAN;
	}

	public List<Customer> Customer;
	public List<CustomerMemberMapping> CustomerMemberMapping;
	public List<NomineeDetails> NomineeDetails;
    public List<PreviousPolicyDetails> PreviousPolicyDetails;
	public Policy Policy;

	public class CustomerMemberMapping {
		public String ClientId;
		public String MemberId;
		public String MemberStatus;
        //External id field : name would be modified later
        //public String ExternalId;
		public String MemberSubStatus;
		//public String PreExistingDiseaseWaitingPeriod;
		public String member_first_inception_date;
		public String cumulativeBonus;
		public String super_ncb_amount;
	}

    public class PreviousPolicyDetails {
        public String PreviousPolicyNumber;
        public String nameOfInsuredPerson;
        public String dateOfFirstEnrollment;
        public String insurer;
        public String policyYear;
        public String product;
        public String typeOfCover;
        public String expiringBasSI;
        public String cumulativeBonus;
        public String expiringWaitingPeriod;
        public String optedSi;
        public String optedProductWP;
        public String waiverOfWPforSI;
    }
	public class Customer {
		public String AadharNo;
		public String AddressLine1;
		public String AddressLine2;
		public String AddressLine3;
		public String AddressType;
        public String Address2Line1;
		public String Address2Line2;
		public String Address2Line3;
		public String PIN;
		public String City;
        public String City2;
        public String PIN2;
		public String State;
        public String State2;
		public String Email;
		public String HomePhone;
		public String Alternatemobile;
		public String CoreSystemId;
		public String Country;
        public String Country1;
		public String DateofBirth;
		public String Occupation;
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
		//public String Nationality1;
		public String PanNo;
		//public String ParentCode;
		public String WhatsappNumber;
        public String HNICustomer;
        public String CEOClubAdvisor;
        public String PriorityCustomer;
        public String SensitiveCustomer;
        public String CustomerRoleType;
		/*public List<CustomerSegments> CustomerSegments;
		public List<CustomerRoles> CustomerRoles;*/
		//public String EffectiveDate;
		//public String InternationalNumber;
		public String NatureDescriptionOfTheBusiness;
		public String Relation;
        public String ContactPersonofEmployer;
        public String RegistrationNumber;
        public String super_ncb_amount;
        public String cumulative_bonus_earned;
        public String RidersOpted;
        public String ChronicDiseaseDescription;
        public String IsChronic;
        public String ped_waiting_period;
        public String expiringWaitingPeriod;
        public String risk_class;
        public String hni_customer;
        public String priority_customer;
        public String ceo_club_advisor_customer;
        public String ped_name;
        public String SumInsured;
        public String UpfrontDiscount;
        public String politically_exposed_person;
        public String district_town;
        public String District2;
        public String BusinessUnit;
        public String CMP_OPD;
        public String Chronic_care;
        public String IsChronicDisease;
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