import { LightningElement, api,track } from 'lwc';

export default class Abhi_HHS_Active extends LightningElement {

    @api recordId;
    @track isLoading = false;

    handleUploadStart() {
        this.isLoading = true;
    }

    handleUploadEnd() {
        this.isLoading = false;
    }

}