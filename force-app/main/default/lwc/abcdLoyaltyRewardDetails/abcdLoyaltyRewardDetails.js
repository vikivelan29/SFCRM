import { LightningElement,api,track } from 'lwc';

export default class AbcdLoyaltyRewardDetails extends LightningElement {
    @api loyaltyrewards;
        @track showPopup = false;
    

    openTransactionPopUp(event){
        this.showPopup = true;
    }

    closePopup() {
        this.showPopup = false;
    }
}