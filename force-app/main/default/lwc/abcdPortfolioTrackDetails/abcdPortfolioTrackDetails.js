import { LightningElement,api } from 'lwc';
import DATANOTFOUND from "@salesforce/label/c.ABCD_Data_Not_Found_Message";
export default class AbcdPortfolioTrackDetails extends LightningElement {
    @api pcdetails;
    @api status;
    @api apiMessage;

    dataNotFoundMessage = DATANOTFOUND;

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