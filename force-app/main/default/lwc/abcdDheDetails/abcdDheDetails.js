import { LightningElement,api } from 'lwc';

export default class AbcdDheDetails extends LightningElement {
    @api dhedetails;
    @api status;
    @api apiMessage;
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {
        return this.status === 'Success' && (!this.dhedetails || this.dhedetails.length === 0 || this.dhedetails == null);
    }
}