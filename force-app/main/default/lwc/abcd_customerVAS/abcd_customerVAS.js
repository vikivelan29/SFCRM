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
                    if(resp.holdingsVASInfo.dheDetails){
                        let dheDetails = resp.holdingsVASInfo.dheDetails;
                        if(dheDetails.lastScanDate){
                            let dtArr = dheDetails.lastScanDate.split('-');
                            dheDetails.lastScanDate = dtArr.join('/');
                        }
                        this.dheDetails = dheDetails;
                    }
                    if(resp.holdingsVASInfo.csDetails){
                        let csDetails = resp.holdingsVASInfo.csDetails;
                        if(csDetails.lastdownloadDate){
                            let dtArr = csDetails.lastdownloadDate.split('-');
                            csDetails.lastdownloadDate = dtArr.join('/');
                        }
                        this.csDetails = csDetails;
                    }
                    if(resp.holdingsVASInfo.loyaltyRewards){
                        let loyaltyRewards = resp.holdingsVASInfo.loyaltyRewards;
                        if(loyaltyRewards.lastLoyaltyCreditDate){
                            let dtArr = loyaltyRewards.lastLoyaltyCreditDate.split('-');
                            loyaltyRewards.lastLoyaltyCreditDate = dtArr.join('/');
                        }
                        if(loyaltyRewards.lastLoyaltyCreditTransaction){
                            let dtArr = loyaltyRewards.lastLoyaltyCreditTransaction.split('-');
                            loyaltyRewards.lastLoyaltyCreditTransaction = dtArr.join('/');
                        }
                        this.loyaltyRewards = loyaltyRewards;
                    }
                }
            }
            this.isLoading = false;
        })
        .catch((error) => {
            this.error = error;
            this.isLoading = false;
        });

    }
}