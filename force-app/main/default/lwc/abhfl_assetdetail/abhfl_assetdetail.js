import { LightningElement, api, track, wire } from 'lwc';
import uploadFile from '@salesforce/apex/ABHFL_AssetFileUploader.uploadFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class ABHFL_AssetDetail_POC extends LightningElement {

    @track loanData=[];
    error;
    rowOffset;
    @api showAddAttachmentModal = false;
    selectedLan;
    @track lanOptions=[];
    isLoanSelected = false;
    @track fileData;
    @api recordId;
    @api detailId;
    @api lan;
    @api isHyperlink;
    showIcon = true;
    @api showQuickAction;
    @api currStage;
    @api stagesAllowingFileUpload;
    @api userId;
    @api ownerId;
    @api attachmentStatus;

    connectedCallback(e){
        if(this.isHyperlink){
            this.showIcon = false;
        }
    }
    get modalHeader(){
        return 'Upload Documents';
    }

    openAddAttachmentModal(event){
        if(this.userId != this.ownerId || (this.stagesAllowingFileUpload && this.stagesAllowingFileUpload.length > 0 && !this.stagesAllowingFileUpload.includes(this.currStage))){
            const selectEvent = new CustomEvent('checkpermissions',{});
            // Fire the custom event
            this.dispatchEvent(selectEvent);
            this.closeModal();
        }
        this.isLoanSelected = false;
        this.showAddAttachmentModal = true;
    }

    closeModal(event){
        this.showAddAttachmentModal = false;
    }
    
    handleFilesChange(event){
        this.template.querySelector('lightning-input').disabled=true;
        if(this.template.querySelector('.slds-button_neutral')){
            this.template.querySelector('.slds-button_neutral').disabled=true;
        }
        const file = event.target.files[0];
        var reader = new FileReader();
        reader.onload = () => {
            var base64 = reader.result.split(',')[1];
            var fileNameList = file.name.split('.');
            var extension = fileNameList[(fileNameList.length - 1)];
            this.fileData = {
                'lan': this.lan,
                'base64': base64,
                'recordId': this.recordId,
                'detailId': this.detailId,
                'extension' : extension
            };
            console.log(this.fileData);
            if(this.fileData){
                this.saveFileToLanHandler();
            }
        }
        reader.readAsDataURL(file);
    }

    saveFileToLanHandler(event){
        const {base64, lan, recordId, detailId,extension} = this.fileData;
        uploadFile({ base64, lan, recordId, detailId, extension }).then(result=>{
            this.fileData = null;
            let title = `File uploaded successfully!!`;
            this.toast(title);
            this.attachmentStatus = true;
            this.showAddAttachmentModal = false;
            if(this.isHyperlink){
                const selectEvent = new CustomEvent('close',{});
                // Fire the custom event
                this.dispatchEvent(selectEvent);
            }
        }).catch((error) => {
            console.log(error);
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