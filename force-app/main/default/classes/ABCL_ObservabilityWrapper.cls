/**
 * @description       : 
 * @author            : nikhil.dhoke@in.ey.com
 * @group             : 
 * @last modified on  : 12-03-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class ABCL_ObservabilityWrapper {

    public Integer totalCases = 0;
    public Integer successfullCases = 0;
    public Integer casesNotSentToIntegration = 0;
    public String integrationType = '';
    public List<CaseDetailsWrapper> caseDetailsList = new List<CaseDetailsWrapper>();
    public List<DWHDetailsWrapper> dwahDetailsList = new List<DWHDetailsWrapper>();

    public class CaseDetailsWrapper {
        public String caseNumber; 
        public String lineOfBusiness; 
        public String businessUnit;
        public Decimal retryAttempt; 
        public String caseType; 
        public String caseSubType; 
        public String lan; 
        public String status; 
        public String source; 
        public String type; 
        public String message; 
        public String description; 
        public String caseCreatedDate; 
        public String requestDate; 
        //public String responseDate;
    }

    public class DWHDetailsWrapper {
        public String jobId; 
        public String operation; 
        public String objectName; 
        public String createdById; 
        public String createdDate; 
        public String systemModstamp; 
        public String state; 
        public String externalIdFieldName; 
        public String numberRecordsProcessed; 
        public String numberRecordsFailed; 
        public String totalProcessingTime; 
        public String apiActiveProcessingTime; 
        public String apexProcessingTime;
    }
}