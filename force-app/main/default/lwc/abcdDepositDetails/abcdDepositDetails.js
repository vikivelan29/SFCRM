import { api, LightningElement } from 'lwc';
import DATANOTFOUND from "@salesforce/label/c.ABCD_Data_Not_Found_Message";

export default class AbcdDepositDetails extends LightningElement {
    @api dsdetails;
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
        return this.status === 'Success' && (!this.dsdetails || this.dsdetails.length === 0 || this.dsdetails == null);
    }
}