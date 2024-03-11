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
    intervalId;
    disableLink = true;
    errorMessage ='';
    failedRecords = 0;
    processedRecords = 0;
    boolShowGreenBar = false;
    processedRecId=[];
    checkStatus = false;
    processComplete = false;

    connectedCallback(){
        this.pollProgress();       
    }
    
    //Polls the uplaod progress from Apex every 3 seconds
    pollProgress(){
        this.intervalId = setInterval(() => {
            this.fetchProgress();
            if(this.processComplete){
                this.stopCallingApex();
                this.boolShowGreenBar = true;
            }
        }, 3000);
    }

    //Fetches the progress to display the result in UI
    fetchProgress() {
        console.log('this.processedRecIds--'+this.processedRecId.length);
        this.errorOccured = false;
        this.errorMessage = '';
        fetchCSVUploadProgress({bulkHeaderId: this.uploadId, processedRecIds: this.processedRecId, checkHeaderStatus: this.checkStatus})
            .then(result => {
                this.disableLink = false;
                if(this.percentageValue != 100){
                    this.failedRecords = this.failedRecords + result.failedRecords;
                    this.processedRecords = this.processedRecords + result.processedRecords;
                    this.percentageValue = Math.round((this.processedRecords / this.totalRecords) * 100);
                    this.processedRecId = [...this.processedRecId, ...result.processedRecIds];
                }
                if(this.percentageValue == 100 && result.processComplete){
                    this.successMessage = '';
                    this.processComplete = true;
                    const uploadCompleteEvent = new CustomEvent('uploadcomplete', {
                        detail: { value: this.percentageValue }
                    });
                    this.dispatchEvent(uploadCompleteEvent);
                    
                }else if(this.percentageValue === 100){
                    this.checkStatus = true;
                }
                
            })
            .catch(error => {
                console.error('Error calling fetchCSVUploadProgress method:', error);
                let errMsg = reduceErrors(error);
                let singleError = Array.isArray(errMsg) ? errMsg[0] : errMsg;
                if(!(singleError.toLowerCase().includes('limit')) && !(singleError.toLowerCase().includes('disconnected'))){
                    this.errorOccured = true;
                    this.errorMessage = singleError + '. The System will continue the upload. Please click on the above Header Record link for Progress';
                }
                
            });
    }

    //Stops the polling
    disconnectedCallback() {
        // Clear the interval when the component is removed from the DOM
        clearInterval(this.intervalId);
    }

    //Stops the polling
    stopCallingApex(){
        clearInterval(this.intervalId);
    }

    //Navigates to the current header record to view the progress
    navigateToRecord(event){
        let strNavigate = "/lightning/r/ASF_Bulk_Upload_Header__c/"+  this.uploadId +"/view";
        window.open(strNavigate,"_blank");
      
    }
}