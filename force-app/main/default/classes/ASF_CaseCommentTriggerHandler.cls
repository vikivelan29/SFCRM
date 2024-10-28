public with sharing class ASF_CaseCommentTriggerHandler extends ASF_VTriggerHandler{
    
    public override void BeforeInsert(List<SObject> newItems){
        validateCaseComment((List<CaseComment>)newItems, null);
    }
    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        validateCaseComment((List<CaseComment>)newItems.values(), (Map<Id, CaseComment>)oldItems);
    }
    public override void BeforeDelete(Map<Id, SObject> oldItems){
        validateCaseComment(null, (Map<Id, CaseComment>)oldItems);
    }    
    public static void validateCaseComment(List<CaseComment> newList, Map<Id, CaseComment> oldMap){
        if(ABCL_CommonCLass.bypassValidation() && !Test.isRunningTest()){            
            createFeedItem(newList, oldMap);
            return;
        }        
        Boolean isSuperUser = FeatureManagement.checkPermission('Bypass_Case_Validation');
        Boolean isDelete = newList==null ? true : false;
        Boolean isUpdate = (oldMap!=null && newList!=null) ? true : false;
        Boolean isInsert = oldMap==null ? true : false;
        List<CaseComment> caseCommentList = isDelete ? oldMap.values() : newList;
        Set<Id> caseIds = new Set<Id>();
        Map<Id,Case> caseIdtoStatusMap = new Map<Id,Case>();
        for(CaseComment caseCommentRec : caseCommentList){            
            caseIds.add(caseCommentRec.ParentId);
        }        
        if(!caseIds.isEmpty()){
            for(Case caseRec : [SELECT Id, isClosed, ownerId,Business_Unit__c from case where Id IN: caseIds]){
                caseIdtoStatusMap.put(caseRec.Id, caseRec);
            }
        }        
        if(!caseIdtoStatusMap.isEmpty()){            
            for(CaseComment caseCommentRec : caseCommentList){                
                if((caseIdtoStatusMap.get(caseCommentRec.ParentId).isClosed == true && !isSuperUser) ||
                   (caseIdtoStatusMap.get(caseCommentRec.ParentId).isClosed == true && isSuperUser && !isInsert)){
                       caseCommentRec.addError(System.Label.ASF_CaseComment_Delete_Msg);
                   }
                if(isUpdate || isDelete){
                    if(UserInfo.getUserId() != caseIdtoStatusMap.get(caseCommentRec.ParentId).ownerId || 
                       UserInfo.getUserId() != caseCommentRec.CreatedById){
                           caseCommentRec.addError(System.Label.ASF_CaseComment_edit_Err_Msg);
                       }
                }
                //[START] Added by Zahed : PR1030924-211
                Case relatedCase = caseIdtoStatusMap.get(caseCommentRec.ParentId);                
                if (relatedCase.Business_Unit__c == System.label.Wellness_BU  &&relatedCase != null && relatedCase.OwnerId != UserInfo.getUserId() && !Test.isRunningTest()) {
                    caseCommentRec.addError(System.Label.Wellness_CaseComment_add_Err_Msg);
                }
                //[END]
            } 
            createFeedItem(newList, oldMap);
        }         
    }

    
    public static void createFeedItem(List<CaseComment> newList, Map<Id, CaseComment> oldMap){
        Boolean isDelete = newList==null ? true : false;
        Boolean isUpdate = (oldMap!=null && newList!=null) ? true : false;
        List<CaseComment> caseCommentList = isDelete ? oldMap.values() : newList;
        if(isUpdate || isDelete){
            String messageBody = '';
            List<FeedItem> feedItemList = new List<FeedItem>();
            for(CaseComment caseCommentRec : caseCommentList){
                String localDate = caseCommentRec.CreatedDate.format('dd/MM/yyyy h:mm a');
                if(isUpdate){
                    messageBody = 'The case comment created on '+localDate+' has been updated from \''+oldMap.get(caseCommentRec.Id).CommentBody+'\' to \''+caseCommentRec.CommentBody+'\'';
                }else if(isDelete){
                    messageBody = 'The case comment \''+caseCommentRec.CommentBody+'\' created on '+localDate+' has been deleted';
                }
                FeedItem feedItem = new FeedItem();
                feedItem.ParentId = caseCommentRec.ParentId;
                feedItem.Type = 'TextPost';
                feedItem.Body = messageBody;
                feedItemList.add(FeedItem);
            }
            if(!feedItemList.isEmpty()){
                try{
                    insert feedItemList;
                }catch(Exception e){
                    System.debug('Exception on ASF_CaseCommentTriggerHandler'+e.getMessage());
                }       
            }
        }
    }
}