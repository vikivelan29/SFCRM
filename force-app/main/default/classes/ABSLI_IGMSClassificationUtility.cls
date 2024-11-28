public with sharing class ABSLI_IGMSClassificationUtility { 
    public static Map<String,Map<String,Set<String>>> getIGMSClassification(){
        List<IGMS_Classification_Mapping__mdt> classificationMTD = [SELECT Id, Policy_Type__c, Complaint_Type__c, Complaint_Description_Id__c FROM IGMS_Classification_Mapping__mdt];
        Map<String,List<IGMS_Classification_Mapping__mdt>> mClassification = new Map<String,List<IGMS_Classification_Mapping__mdt>>();
        Map<String,Map<String,Set<String>>> mClassificationIGMS = new Map<String,Map<String,Set<String>>>();
        
        for(IGMS_Classification_Mapping__mdt mdt : classificationMTD){
            if(!mClassification.containsKey(mdt.Complaint_Type__c)){
                mClassification.put(mdt.Complaint_Type__c, new List<IGMS_Classification_Mapping__mdt>());
            }
            if(!mClassificationIGMS.containsKey(mdt.Complaint_Type__c)){
                mClassificationIGMS.put(mdt.Complaint_Type__c, new Map<String,Set<String>>());
            }
            if(!mClassificationIGMS.get(mdt.Complaint_Type__c).containsKey(mdt.Complaint_Description_Id__c)){
                mClassificationIGMS.get(mdt.Complaint_Type__c).put(mdt.Complaint_Description_Id__c, new Set<String>());
            }
            mClassificationIGMS.get(mdt.Complaint_Type__c).get(mdt.Complaint_Description_Id__c).add(mdt.Policy_Type__c);
        }
        return mClassificationIGMS;
    } 
    public static validationWrapper validateCurrentSelection(Map<String,Map<String,Set<String>>> mClassificationIGMS,
                                                Case caseRecord)
    {
        validationWrapper cls = new validationWrapper();
        if(mClassificationIGMS.containsKey(caseRecord.IGMS_Complaint_Type_Code__c)){
            if(mClassificationIGMS.get(caseRecord.IGMS_Complaint_Type_Code__c).containsKey(caseRecord.CCC_External_Id__c)){
                if(!mClassificationIGMS.get(caseRecord.IGMS_Complaint_Type_Code__c).get(caseRecord.CCC_External_Id__c).contains(caseRecord.ABSLI_Case_Detail__r.IGMS_type_of_policy__c)){
                    cls.bErrorOccured = true;
                    cls.errorMessage = 'Selected IGMS Type of Policy value is not correct as per IGMS Classification. Please select right value.';
                }
            }
        }
        return cls;
    }
    public class validationWrapper{
        public boolean bErrorOccured{get;set;}
        public string errorMessage{get;set;}
        public validationWrapper(){
            this.bErrorOccured = false;
            this.errorMessage = '';
        }
    }
}