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
                        if(dheDetails.lastScanDate){
                            //let dtArr = dheDetails.lastScanDate.split('-');
                            //dheDetails.lastScanDate = dtArr.join('/');
                            dheDetails.lastScanDate = dheDetails.lastScanDate.includes('T') ? 
                                                      dheDetails.lastScanDate.split('T')[0] : dheDetails.lastScanDate;
                        } 
                        if(dheDetails.newScanDate){
                            dheDetails.newScanDate = dheDetails.newScanDate.includes('T')?
                                                     dheDetails.newScanDate.split('T')[0]: dheDetails.newScanDate;
                        }
                        this.dheDetails = dheDetails;
                    }
                    if(resp.holdingsVASInfo.csDetails){
                        let csDetails = resp.holdingsVASInfo.csDetails;
                        if(csDetails.experianLastdownloadDate){
                            csDetails.experianLastdownloadDate = csDetails.experianLastdownloadDate.includes('T') ?
                                                                csDetails.experianLastdownloadDate.split('T')[0] : csDetails.experianLastdownloadDate;
                        }
                        if(csDetails.equifaxLastdownloadDate){
                            csDetails.equifaxLastdownloadDate = csDetails.equifaxLastdownloadDate.includes('T') ?
                                                                csDetails.equifaxLastdownloadDate.split('T')[0] : csDetails.equifaxLastdownloadDate;
                        }
                        if(csDetails.experianNewDownloadDate){
                            csDetails.experianNewDownloadDate = csDetails.experianNewDownloadDate.includes('T') ?
                                                                csDetails.experianNewDownloadDate.split('T')[0] : csDetails.experianNewDownloadDate;
                        }
                        if(csDetails.equifaxNewDownloadDate){
                            csDetails.equifaxNewDownloadDate = csDetails.equifaxNewDownloadDate.includes('T') ?
                                                                csDetails.equifaxNewDownloadDate.split('T')[0] : csDetails.equifaxNewDownloadDate;
                        }
                        this.csDetails = csDetails;
                    }
                    if(resp.holdingsVASInfo.loyaltyRewards){
                        let loyaltyRewards = resp.holdingsVASInfo.loyaltyRewards;
                        if(loyaltyRewards.lastLoyaltyCreditDate){
                            loyaltyRewards.lastLoyaltyCreditDate = loyaltyRewards.lastLoyaltyCreditDate.includes('T') ?
                                                            loyaltyRewards.lastLoyaltyCreditDate.split('T')[0] : loyaltyRewards.lastLoyaltyCreditDate;
                        }
                        if(loyaltyRewards.lastLoyaltyCreditTransaction){ 
                            loyaltyRewards.lastLoyaltyCreditTransaction = loyaltyRewards.lastLoyaltyCreditTransaction.includes('T') ?
                                                            loyaltyRewards.lastLoyaltyCreditTransaction.split('T')[0] : loyaltyRewards.lastLoyaltyCreditTransaction;
                        }
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
