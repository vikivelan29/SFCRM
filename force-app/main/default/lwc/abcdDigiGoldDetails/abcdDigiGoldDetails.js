import { LightningElement,api,track } from 'lwc';

export default class AbcdDigiGoldDetails extends LightningElement {
    @api dgdetails;
    @track showPopup = false;

    openTransactionPopUp(event){
        this.showPopup = true;
    }

    closePopup() {
        this.showPopup = false;
    }

}