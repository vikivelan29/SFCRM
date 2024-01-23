import { LightningElement, api, track, wire } from 'lwc';
import uploadFile from '@salesforce/apex/ABHFL_AssetFileUploader.uploadFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ABHFL_AssetDetail_POC extends LightningElement {

    @track loanData=[];
    error;
    rowOffset;
    showAddAttachmentModal = false;
    selectedLan;
    @track lanOptions=[];
    isLoanSelected = false;
    @track fileData;
    @api recordId;
    @api detailId;

    get modalHeader(){
        return 'Upload Documents';
    }

    openAddAttachmentModal(event){
        this.isLoanSelected = false;
        this.showAddAttachmentModal = true;
    }

    closeModal(event){
        this.showAddAttachmentModal = false;
    }
    
    handleFilesChange(event){
        const file = event.target.files[0];
        var reader = new FileReader();
        reader.onload = () => {
            var base64 = reader.result.split(',')[1];
            this.fileData = {
                'filename': file.name,
                'base64': base64,
                'recordId': this.recordId,
                'detailId': this.detailId
            };
            console.log(this.fileData);
        }
        reader.readAsDataURL(file);
    }

    saveFileToLanHandler(event){
        const {base64, filename, recordId, detailId} = this.fileData;
        uploadFile({ base64, filename, recordId, detailId }).then(result=>{
            this.fileData = null;
            let title = `${filename} uploaded successfully!!`;
            this.toast(title);
            this.showAddAttachmentModal = false;
        });
    }

    toast(title){
        const toastEvent = new ShowToastEvent({
            title, 
            variant:"success"
        });
        this.dispatchEvent(toastEvent);
    }

}