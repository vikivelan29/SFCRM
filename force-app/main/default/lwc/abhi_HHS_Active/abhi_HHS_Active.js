import { LightningElement, api,track } from 'lwc';

export default class Abhi_HHS_Active extends LightningElement {


    errorMessages

    @api recordId;
    @track isLoading = false;

    handleUploadStart() {
        this.isLoading = true;
    }

    handleUploadEnd() {
        this.isLoading = false;
    }
    childmessage = false;

    updateMessage(event) {
        this.message = event.detail.message;
    }

}