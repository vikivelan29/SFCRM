import { api, LightningElement } from 'lwc';

export default class AbcdDepositDetails extends LightningElement {
    @api dsdetails;
    @api status;
    @api apiMessage;
    
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {
        return this.status === 'Success' && (!this.dsdetails || this.dsdetails.length === 0 || this.dsdetails == null);
    }
}