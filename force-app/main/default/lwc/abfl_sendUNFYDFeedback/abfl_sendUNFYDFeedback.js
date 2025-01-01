import { LightningElement, api } from 'lwc';
import handleRecord from '@salesforce/apex/ABFL_submitFeedbackToUNFYD.sendUNFYDFeedback';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Abfl_sendUNFYDFeedback extends LightningElement {
    @api recordId; // This is automatically provided on a record page

    handleClick() {
        handleRecord({ recordId: this.recordId })
            .then(result => {
                this.showToast('Success', result, 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}