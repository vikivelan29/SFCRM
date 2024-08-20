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
    message;
    label = {
        errorMessage,
        pageSize,
        faTitle 
    };
    displayError=false;

    connectedCallback(){
        this.message=this.label.errorMessage;
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
        console.log('In getDetails>>>');
        getFADetails({customerId: this.recordId})
        .then(result => {
            console.log('Result>>>>', result);
            if(result.StatusCode == 1000){
                this.displayError=false;
                let showData = [];
                result.customerAppointments.forEach(element => {
                    showData = [...element.bookingHistories.map(booking => ({
                        bookingId: element.bookingId,
                        ...booking
                    }))];
                });
                console.log('showData>>>>', JSON.stringify(showData));
                this.data=showData;
                this.isLoading=false;
                this.showRecords=true;
            }
            else if(result.StatusCode == 1001){
                this.message = result.info.messageDesc;
                this.isLoading=false;
                this.displayError=true;
                this.showRecords=false;
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