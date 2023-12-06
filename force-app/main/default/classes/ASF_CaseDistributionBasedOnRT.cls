public class ASF_CaseDistributionBasedOnRT {
    public static Final ID interactionRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
    public static Final ID frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
    public static Map<Id,List<Case>> getCaseByRecordType(List<Case> newList){
        Map<Id,List<Case>> mRecordTypeVsCases = new Map<Id,List<Case>>();
        
        for(Case c : newList){
            if(c.RecordTypeId == interactionRecordTypeId){
                if(!mRecordTypeVsCases.containsKey(interactionRecordTypeId))
                    mRecordTypeVsCases.put(interactionRecordTypeId,new List<Case>());
                mRecordTypeVsCases.get(interactionRecordTypeId).add(c);
            }
            else if(c.RecordTypeId == frameworkRecordTypeId){
                if(!mRecordTypeVsCases.containsKey(frameworkRecordTypeId))
                    mRecordTypeVsCases.put(frameworkRecordTypeId,new List<Case>());
                mRecordTypeVsCases.get(frameworkRecordTypeId).add(c);
            }
        }
        return mRecordTypeVsCases;
        
    }
    
}