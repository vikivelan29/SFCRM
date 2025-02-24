import { LightningElement,api } from 'lwc';

export default class AbcdDematDetails extends LightningElement {
    @api dmdetails;

    @api status;
    @api apiMessage;
    
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {
        return this.status === 'Success' && (!this.dmdetails || this.dmdetails.length === 0 || this.dmdetails == null);
    }
}
