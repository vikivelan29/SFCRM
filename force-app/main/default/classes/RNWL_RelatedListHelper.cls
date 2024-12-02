public without sharing class RNWL_RelatedListHelper {
    public static final Map<Schema.DisplayType, String> DATA_TYPE_TO_COL_TYPE_MAP = new Map<Schema.DisplayType, String>{
        Schema.DisplayType.Date => 'string',
        Schema.DisplayType.DateTime => 'date',
        Schema.DisplayType.Currency => 'currency',
        Schema.DisplayType.Phone => 'phone',
        Schema.DisplayType.URL => 'url',
        Schema.DisplayType.String => 'string',
        Schema.DisplayType.TextArea => 'string',
        Schema.DisplayType.Picklist => 'string'
    };

    public class DataWrapper {
        @AuraEnabled public String communicationName;
        @AuraEnabled public String emailID;
        @AuraEnabled public String status;
        @AuraEnabled public String createdOn;
        @AuraEnabled public String createdBy;
        @AuraEnabled public String recordId;

        public DataWrapper(EmailMessage msgInstance, PE_Logger__c loggerInstance) {
            this.communicationName = msgInstance.EmailTemplate.Name == null ? msgInstance.Subject : msgInstance.EmailTemplate.Name;
            this.emailID = msgInstance.ToAddress;
            this.status = msgInstance.Status;
            this.recordId = msgInstance.Id;
            if (loggerInstance == null) {
                this.createdOn = msgInstance.CreatedDate.format();
                this.createdBy = msgInstance.CreatedBy.Name;
            } else {
                this.createdOn = loggerInstance.CreatedDate.format();
                this.createdBy = loggerInstance.CreatedBy.Name;
            }
        }
    }

    @AuraEnabled
    public static QueryResponseWrapper getRelatedRecords(String mode, String recordId, Boolean viewAll) {
        QueryResponseWrapper responseInst = new QueryResponseWrapper();
        try {
            if (mode == 'Email Message') {
                responseInst.emailData = new List<DataWrapper>();
                Map<String, PE_Logger__c> logsByName = new Map<String, PE_Logger__c>();
                for (PE_Logger__c each : [SELECT Id, Email_Template_Name__c, CreatedDate, CreatedBy.Name FROM PE_Logger__c WHERE Opportunity_ID__c = :recordId]) {
                    String keyVal = each.Email_Template_Name__c + String.valueOf(each.CreatedDate).left(10);
                    logsByName.put(keyVal, each);
                }
                List<EmailMessage> emailMessages = new List<EmailMessage>();
                if (viewAll != null && viewAll) {
                    emailMessages = [SELECT ID, EmailTemplate.Name, ToAddress, toLabel(Status), EmailTemplate.DeveloperName, CreatedBy.Name,
                        Subject, CreatedDate FROM Emailmessage WHERE RelatedToId = :recordId];
                } else {
                    emailMessages = [SELECT ID, EmailTemplate.Name, ToAddress, toLabel(Status), EmailTemplate.DeveloperName, CreatedBy.Name,
                        Subject, CreatedDate FROM Emailmessage WHERE RelatedToId = :recordId LIMIT 5];
                }
                for (EmailMessage each : emailMessages) {
                    String keyVal = each.EmailTemplate.DeveloperName + String.valueOf(each.CreatedDate).left(10);
                    responseInst.emailData.add(new DataWrapper(each, logsByName.get(keyVal)));
                }
                responseInst.columns = new List<ColumnWrapper>{
                    new ColumnWrapper('Communication Name', 'communicationName', 'string'),
                    new ColumnWrapper('Email ID', 'emailID', 'string'),
                    new ColumnWrapper('Email', 'status', 'string'),
                    new ColumnWrapper('Created On', 'createdOn', 'string'),
                    new ColumnWrapper('Created By', 'createdBy', 'string')
                };
            } else {
                String query;
                SObjectType objectDescribe;
                List<String> fieldsList = new List<String>{'Id', 'Name', 'Next_Call_Back_Date_Time__c', 'Disposition_L1__c', 'Disposition_L2__c',
                    'Disposition_L3__c', 'Call_Date_Time__c', 'Agent_Name__r.Name', 'Remarks__c', 'Calling_Unit__c', 'Calling_Mode__c'};
                if (mode == 'Best Disposition') {
                    query = 'SELECT Id, Name, Next_Call_Back_Date_Time__c, Disposition_L1__c, Disposition_L2__c, Disposition_L3__c, Call_Date_Time__c, '
                        + 'Agent_Name__r.Name, Remarks__c, Calling_Unit__c, Calling_Mode__c FROM Dispositions__c WHERE Renewal_Request__c = :recordId '
                        + 'ORDER BY Priority__c ASC NULLS LAST, Call_Date_Time__c DESC LIMIT 1';
                } else if (mode == 'Last Disposition') {
                    query = 'SELECT Id, Name, Next_Call_Back_Date_Time__c, Disposition_L1__c, Disposition_L2__c, Disposition_L3__c, Call_Date_Time__c, '
                        + 'Agent_Name__r.Name, Remarks__c, Calling_Unit__c, Calling_Mode__c FROM Dispositions__c WHERE Renewal_Request__c = :recordId '
                        + 'ORDER BY Call_Date_Time__c DESC LIMIT 1';
                }
                objectDescribe = Schema.getGlobalDescribe().get('Dispositions__c');
                responseInst.columns = new List<ColumnWrapper>();
                responseInst.data = Database.query(query);
                Map<String, Schema.SObjectField> fieldDetails = objectDescribe.getDescribe().fields.getMap();
                Schema.DescribeFieldResult describeResult;
                for (String each : fieldsList) {
                    describeResult = fieldDetails.get(each.toLowerCase())?.getDescribe();
                    if (describeResult == null) {
                        if (each.toLowerCase()?.contains('.')) {
                            describeResult = fieldDetails.get(each.toLowerCase().substringBefore('.').replace('__r', '__c'))?.getDescribe();
                            responseInst.columns.add(new ColumnWrapper(describeResult.getLabel(), each, 'string'));
                        } else {
                            responseInst.columns.add(new ColumnWrapper(describeResult.getLabel(), each, 'string'));
                        }
                    } else if (each != 'id' && describeResult.getType() != Schema.DisplayType.Reference){
                        responseInst.columns.add(new ColumnWrapper(describeResult.getLabel(), each, DATA_TYPE_TO_COL_TYPE_MAP.get(describeResult.getType())));
                    }
                }
            }
            return responseInst;
        } catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class QueryResponseWrapper {
        @AuraEnabled public List<sObject> data;
        @AuraEnabled public List<ColumnWrapper> columns;
        @AuraEnabled public List<DataWrapper> emailData;
    }

    public class ColumnWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        @AuraEnabled public TypeAttributes typeAttributes;

        public ColumnWrapper(String label, String fieldName, String type) {
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
            if (this.fieldName == 'Name' || this.fieldName == 'communicationName') {
                this.typeAttributes = new TypeAttributes();
                this.typeAttributes.label = new LabelWrapper();
                this.typeAttributes.label.fieldName = this.fieldName;
                this.type = 'url';
                this.fieldName = 'RecordLink';
            }
            if (this.type == 'date') {
                this.typeAttributes = new TypeAttributes(true);
            }
        }
    }

    public class TypeAttributes {
        @AuraEnabled public LabelWrapper label;
        @AuraEnabled public String target = '_blank';
        @AuraEnabled public String year;
        @AuraEnabled public String month;
        @AuraEnabled public String day;
        @AuraEnabled public String hour;
        @AuraEnabled public String minute;

        public TypeAttributes() {}
        public TypeAttributes(Boolean isDate) {
            this.year = 'numeric';
            this.month = '2-digit';
            this.day = '2-digit';
            this.hour = '2-digit';
            this.minute = '2-digit';
        }
    }

    public class LabelWrapper {
        @AuraEnabled public String fieldName;
    }

    @AuraEnabled
    public static void updateOpportunityFields(String recordId, String linkVal, Decimal amountVal) {
        try {
            Opportunity oppRec = new Opportunity(Id = recordId, Razor_Pay_Link__c = linkVal, Razor_Pay_Amount__c = amountVal);
            update oppRec;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}