import { LightningElement,api } from 'lwc';

export default class AbcdPortfolioTrackDetails extends LightningElement {
    @api pcdetails;
    @api status;
    @api apiMessage;
    
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {
        return this.status === 'Success' && (!this.pcdetails || this.pcdetails.length === 0 || this.pcdetails == null);
    }
}