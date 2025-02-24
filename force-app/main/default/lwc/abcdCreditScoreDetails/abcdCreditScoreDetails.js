import { LightningElement,api } from 'lwc';

export default class AbcdCreditScoreDetails extends LightningElement {
    @api csdetails;

    @api status;
    @api apiMessage;
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {
        return this.status === 'Success' && (!this.csdetails || this.csdetails.length === 0 || this.csdetails == null);
    }
}