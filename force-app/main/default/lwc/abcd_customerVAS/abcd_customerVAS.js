import { LightningElement, track, api } from 'lwc';
import getTabData from '@salesforce/apex/ABCD_CustomerInfoController.getTabData';

export default class Abcd_customerVAS extends LightningElement 
{
    @api recordId;
    error;
    tbLabel = 'VAS';
    isLoading = false;
    @track dheDetails;
    @track csDetails;
    @track loyaltyRewards;
    @track status;
    @track apiMessage;

    connectedCallback(){
        this.fetchVASHoldings();
    }

    handleRefresh(){
        this.fetchVASHoldings();
    }

    fetchVASHoldings(){
        this.isLoading = true;
        getTabData({ tabLabel:this.tbLabel , recordId: this.recordId})
        .then((data) => {
            if (data) {
                let resp = JSON.parse(data);
                if(resp.status == 'Success'){
                    this.status = resp.status;
                    this.apiMessage = resp.message;
                    if(resp.holdingsVASInfo.dheDetails){
                        let dheDetails = resp.holdingsVASInfo.dheDetails;
                        this.dheDetails = dheDetails;
                    }
                    if(resp.holdingsVASInfo.csDetails){
                        let csDetails = resp.holdingsVASInfo.csDetails;
                        this.csDetails = csDetails;
                    }
                    if(resp.holdingsVASInfo.loyaltyRewards){
                        let loyaltyRewards = resp.holdingsVASInfo.loyaltyRewards;
                        this.loyaltyRewards = loyaltyRewards;
                    }
                }
                this.status = resp.status;
                this.apiMessage = resp.message;
                this.isLoading = false;
            }
            this.isLoading = false;
        })
        .catch((error) => {
            this.error = error;
            this.isLoading = false;
        });

    }
}
