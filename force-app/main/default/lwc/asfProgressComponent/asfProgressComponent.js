import { LightningElement, api, wire } from 'lwc';
import fetchCSVUploadProgress from '@salesforce/apex/ASF_BulkCsvController.fetchCSVUploadProgress';
import { reduceErrors } from 'c/asf_ldsUtils';

export default class AsfProgressComponent extends LightningElement {
    @api operationName;
    @api uploadId;
    @api successMessage = '';
    @api totalRecords = 0;
    percentageValue = 0;
    errorOccured = false;
    disableLink = true;
    errorMessage ='';
    failedRecords = 0;
    processedRecords = 0;
    processedRecId=[];
    checkStatus = false;
    processComplete = false;

   async connectedCallback(){
        await this.pollProgress();       
    }
    
    //Polls the uplaod progress from Apex every 3 seconds
    async pollProgress() {
        await this.fetchProgress();
        if (!this.processComplete) {
            // Schedule the next run after 3 seconds
            setTimeout(async () => {
                await this.pollProgress();
            }, 3000);
        }
    }

    //Fetches the progress to display the result in UI
    async fetchProgress() {
        console.log('this.processedRecIds--'+this.processedRecId.length);
        this.errorOccured = false;
        this.errorMessage = '';
        let result = await fetchCSVUploadProgress({bulkHeaderId: this.uploadId, processedRecIds: this.processedRecId, checkHeaderStatus: this.checkStatus})
        .catch(error => {
            console.error('Error calling fetchCSVUploadProgress method:', error);
            let errMsg = reduceErrors(error);
            let singleError = Array.isArray(errMsg) ? errMsg[0] : errMsg;
            if(!(singleError.toLowerCase().includes('limit')) && !(singleError.toLowerCase().includes('disconnected'))){
                this.errorOccured = true;
                this.errorMessage = singleError + '. The System will continue the upload. Please click on the above Header Record link for Progress';
            }    
        });
        if(result && result != null){
            this.disableLink = false;
            if(this.processedRecords < this.totalRecords){
                this.failedRecords = this.failedRecords + result.failedRecords;
                this.processedRecords = this.processedRecords + result.processedRecords;
                this.percentageValue = Math.round((this.processedRecords / this.totalRecords) * 100);
                this.processedRecId = [...this.processedRecId, ...result.processedRecIds];
                const uniqueIdsSet = new Set(this.processedRecId);
                this.processedRecId = Array.from(uniqueIdsSet);
            }
            if(this.processedRecords === this.totalRecords && result.processComplete){
                this.successMessage = '';
                this.processComplete = true;
                const uploadCompleteEvent = new CustomEvent('uploadcomplete', {
                    detail: { value: this.percentageValue }
                });
                this.dispatchEvent(uploadCompleteEvent);
                
            }else if(this.processedRecords === this.totalRecords){
                this.checkStatus = true;
            }
        }
    }

    //Navigates to the current header record to view the progress
    navigateToRecord(event){
        let strNavigate = "/lightning/r/ASF_Bulk_Upload_Header__c/"+  this.uploadId +"/view";
        window.open(strNavigate,"_blank");
      
    }
}