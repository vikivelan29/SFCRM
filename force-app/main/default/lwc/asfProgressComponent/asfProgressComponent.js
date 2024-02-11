import { LightningElement, api, wire } from 'lwc';
import fetchCSVUploadProgress from '@salesforce/apex/ASF_BulkCsvController.fetchCSVUploadProgress';

export default class AsfProgressComponent extends LightningElement {
    @api operationName;
    @api uploadId;
    percentageValue = 0;
    errorOccured = false;
    intervalId;
    disableLink = true;
    errorMessage ='';
    totalRecords = 0;
    failedRecords = 0;
    processedRecords = 0;
    boolShowGreenBar = false;

    strGenericError = 'An unexpected error occured. Please connect with the System Administrator';

    connectedCallback(){
        this.pollProgress();       
    }
    
    pollProgress(){
        this.intervalId = setInterval(() => {
            this.fetchProgress();
            if(this.percentageValue == 100){
                this.stopCallingApex();
                this.boolShowGreenBar = true;
            }
        }, 3000);
    }

    fetchProgress() {
        fetchCSVUploadProgress({bulkHeaderId: this.uploadId})
            .then(result => {
                this.totalRecords = result.totalRecords;
                this.failedRecords = result.failedRecords;
                this.processedRecords = result.processedRecords;
                this.percentageValue = Math.round((this.processedRecords / this.totalRecords) * 100);

                this.disableLink = false;
                if(this.percentageValue == 100){
                    const uploadCompleteEvent = new CustomEvent('uploadcomplete', {
                        detail: { value: this.percentageValue }
                    });
                    this.dispatchEvent(uploadCompleteEvent);
                }
                
            })
            .catch(error => {
                console.error('Error calling fetchCSVUploadProgress method:', error);
            });
    }

    disconnectedCallback() {
        // Clear the interval when the component is removed from the DOM
        clearInterval(this.intervalId);
    }

    stopCallingApex(){
        clearInterval(this.intervalId);
    }

    navigateToRecord(event){
        let strNavigate = "/lightning/r/ASF_Bulk_Upload_Header__c/"+  this.uploadId +"/view";
        window.open(strNavigate,"_blank");
      
    }
}