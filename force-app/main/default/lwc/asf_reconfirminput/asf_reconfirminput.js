import { LightningElement, api, track } from 'lwc';

export default class Asf_reconfirminput extends LightningElement {
    @api ccfield;
    @track originalTextValue = '';
    @track confirmTextValue = '';
    @track bConfirmationTextNotMatching = true;
    @api fieldNameToSearch = '';
    @track MICR_CODE = '000000000';
    @api recordId;
    @track IFSC_Code = '';


    handleOriginalTextChange(event) {
        this.originalTextValue = event.target.value;
        this.confirmationCheck();
    }
    handleConfirmTextChange(event) {
        let val = event.target.value;
        this.confirmTextValue = val;
        this.confirmationCheck();
    }
    varifyConfirmFieldPopup(event) {
        if (this.confirmTextValue == this.originalTextValue) {
            event.preventDefault();

            let arr_fieldDetails = [];
            let propConfirmedField = {};
            propConfirmedField.FieldAPINAme = this.fieldNameToSearch;
            propConfirmedField.fieldValue = this.confirmTextValue;
            propConfirmedField.status = 'Success';
            arr_fieldDetails.push(propConfirmedField);
            this.dispatchEvent(new CustomEvent("case360fieldextn",
                {
                    detail: {
                        arr_fieldDetails
                    }
                }
            ));
            this.cancelConfirmFieldPopup();
        }
    }
    confirmationCheck() {
        if (this.originalTextValue == this.confirmTextValue) {
            this.bConfirmationTextNotMatching = false;
            this.iconClass = 'successBtn';
        }
        else {
            this.bConfirmationTextNotMatching = true;
        }
    }
    cancelConfirmFieldPopup(event) {
        this.dispatchEvent(new CustomEvent("closepopup"));
    }
    disconnectedCallback() {
        this.ccfield = undefined;
    }
    handleOriginalAndConfirmationText(event) {
        let val = event.target.value;
        this.confirmTextValue = val;
        this.originalTextValue = val;
    }

}