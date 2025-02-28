import { LightningElement,api } from 'lwc';
import DATANOTFOUND from "@salesforce/label/c.ABCD_Data_Not_Found_Message";

export default class AbcdDematDetails extends LightningElement {
    @api dmdetails;

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
        return this.status === 'Success' && (!this.dmdetails || this.dmdetails.length === 0 || this.dmdetails == null);
    }
}
