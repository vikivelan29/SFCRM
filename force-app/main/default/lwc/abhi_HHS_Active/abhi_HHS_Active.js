import { LightningElement, api,track } from 'lwc';

export default class Abhi_HHS_Active extends LightningElement {


    
    @track errorMessages = '';
    @track displayError = false;



    @api recordId;
    @track isLoading = false;

    handleUploadStart() {
        this.isLoading = true;
    }

    handleUploadEnd() {
        this.isLoading = false;
    }

    updateMessage(event) {
        displayError=true;
        this.errorMessages = event.detail.message;
    }

}