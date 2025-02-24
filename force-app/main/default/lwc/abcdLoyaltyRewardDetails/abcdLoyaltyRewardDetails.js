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

    @api status;
    @api apiMessage;
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {
        return this.status === 'Success' && (!this.loyaltyrewards || this.loyaltyrewards.length === 0 || this.loyaltyrewards == null);
    }
}
