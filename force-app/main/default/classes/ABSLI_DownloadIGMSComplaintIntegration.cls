public with sharing class ABSLI_DownloadIGMSComplaintIntegration {
   /**
    * @description Initiate downloadAttachment from IGMS
    *
    * @param caseRec - IGMS Document Record ID
    * @return void
    */
    @AuraEnabled
    public static void downloadAttachment(string recId){
        try {
            List<ABSLI_IGMS_Document__c> igmsDocument = [Select id,Case__r.CaseNumber,IRDA_Token_Number__c,Document_Id__c,
                                                         File_Name__c,Case__r.Business_Unit__c
                                                        from ABSLI_IGMS_Document__c where id =: recId limit 1];

            if(igmsDocument.size() > 0){
                DownloadAttachmentWrapper downloadWrapper = new DownloadAttachmentWrapper();
                downloadWrapper.caseId = igmsDocument[0].Case__r.CaseNumber;
                downloadWrapper.IRDA_Token_no = igmsDocument[0].IRDA_Token_Number__c;
                downloadWrapper.DocID = igmsDocument[0].Document_Id__c;
                downloadWrapper.fileName = igmsDocument[0].File_Name__c;

                igmsDocument[0].Request__c = JSON.serialize(downloadWrapper);
                Database.SaveResult result = Database.update(igmsDocument[0]);

                Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e();
                caseIntOut.Business_Unit__c = igmsDocument[0].Case__r.Business_Unit__c;
                caseIntOut.Request_Payload__c = JSON.serialize(downloadWrapper);
                caseIntOut.Integration_Name__c = ABSLI_Constants.IGMS_UPDATECOMPLAINT_DOWNLOAD_SRV_NAME;
                caseIntOut.ServiceName__c = ABSLI_Constants.IGMS_UPDATECOMPLAINT_DOWNLOAD_SRV_NAME;
                caseIntOut.Case_Integration_ID__c = igmsDocument[0].Id;
                Database.SaveResult publishResults = EventBus.publish(caseIntOut);
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class DownloadAttachmentWrapper{
        public string caseId;
        public string IRDA_Token_no;
        public string DocID;
        public string fileName;
    }
}