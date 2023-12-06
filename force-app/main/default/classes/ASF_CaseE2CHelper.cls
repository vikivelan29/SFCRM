public with sharing class ASF_CaseE2CHelper {
    public static void blockOOOCases(list<case> newItems){
        set<String> exclusionSubjectKeywords = getExclusionSubjects();
        for(case e2c : newItems){
            for(String exclusionKeyword : exclusionSubjectKeywords){
                if(String.isEmpty(e2c.subject))
                    continue;
                if(e2c.Origin?.toUpperCase().contains('EMAIL') && e2c.subject.tolowercase().contains(exclusionKeyword))
                    e2c.addError('Email having subject keyword %' + exclusionKeyword + '% not allowed in Email-to-Case.');
            }
        }
    }
    static set<String> getExclusionSubjects(){
        set<String> exclusionSubjectKeywords = new set<String>();
        for(Configuration__c cf : [select ExclusionSubjectKeyword__c from Configuration__c where Active__c = true and RecordType.DeveloperName = 'OOO_Blockers'])
            if(String.isNotBlank(cf.ExclusionSubjectKeyword__c))
                exclusionSubjectKeywords.add(cf.ExclusionSubjectKeyword__c.trim().tolowercase());
        return exclusionSubjectKeywords;
    }
    public static void setBusinessUnitValue(list<case> newItems){
        
    }
}