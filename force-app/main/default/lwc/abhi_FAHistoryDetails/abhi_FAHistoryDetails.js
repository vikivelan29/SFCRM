import { LightningElement, api } from 'lwc';
import getFADetails from '@salesforce/apex/ABHI_FAHistoryDetailsController.getFADetails';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import faTitle from '@salesforce/label/c.ABHI_FitnessAppDetails';

export default class Abhi_FAHistoryDetails extends LightningElement {
    @api recordId;
    showRecords = false;
    isLoading = false;
    label = {
        errorMessage,
        pageSize,
        faTitle 
    };
    displayError=false;

    connectedCallback(){
        this.isLoading = true;
        getColumns({configName:'ABHI_FADetailsView'})
        .then(result => {
                this.columns = [
                    ...result.map(col => ({
                        label: col.MasterLabel,
                        fieldName: col.Api_Name__c,
                        type: col.Data_Type__c,
                        cellAttributes: { alignment: 'left' }
                    })),
                ];
                this.getDetails();
            })
        .catch(error => {
                // todo: remove hardcoding
                console.error('error in COlumn fetch>>>', error);
            });
        
    }

    getDetails(){
        getFADetails({customerId: this.recordId})
        .then(result => {
            if(result.StatusCode == 1000){
                this.displayError=false;
                let showData = [];
                result.customerAppointments.forEach(element => {
                    showData = [...element.bookingHistories.map(booking => ({
                        bookingId: element.bookingId,
                        ...booking
                    }))];
                });
                this.data=showData;
                this.isLoading=false;
                this.showRecords=true;
            }
            else{
                this.isLoading=false;
                this.displayError=true;
                this.showRecords=false;
            }
        })
        .catch(error => {
            this.isLoading=false;
            this.displayError=true;
                this.showRecords=false;
            console.error('error in getdetails>>>', error);
        });
    }

    handleRefresh(){
        this.isLoading=true;
        this.showData=false;
        this.getDetails();
    }
}