import { LightningElement, api, track } from 'lwc';
import GetFALevelDetails from '@salesforce/apex/ABHI_FALevelDetails_Controller.GetFALevelDetails';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Abhil_FALevelDetails extends LightningElement {

    @api recordId;
    @track startDate = '';
    @track endDate = '';
    @track records = [];
    @track columns = [];
    @track error;
    displayTable=false;
    @track integrationResp;
    @track displayErrorSearch = false;
    @track data;
    @track isLoading = false;
    @track errorMessages = '';
    @track displayError = false;


    get isSearchDisabled() {
        if (!this.startDate || !this.endDate) {
            return true; // Disable if either date is empty
        }        
        //const start = new Date(this.startDate);
        //const end = new Date(this.endDate);
        //return end <= start; 
  }

    showRecords = false;
    label = {
        errorMessage: 'Error in message',
        pageSize: 5
    };


    handleStartDateChange(event) {
        this.startDate = event.target.value;
        this.validateDates();
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
        this.validateDates();
    }

    handleSearchClick() {
        
        // const EventDates = {
        //     startDate: this.startDate,
        //     endDate: this.endDate
        // };

        if (this.isSearchDisabled) {
            return; // Prevent search if invalid
        }
        this.isLoading = true;

        GetFALevelDetails({ customerId: this.recordId, fromDate: this.startDate, toDate: this.endDate })
            .then(result => {
                this.isLoading = false;
               this.displayTable=false;
                this.result = result;
console.log('result' ,result);
            let StatusCode = result.StatusCode;
            console.log('StatusCode', result.StatusCode);

            if(StatusCode == 1000) {
                this.displayTable=true;
                this.showRecords=true;
                
                let data = [];
                data.push(result);
                //this.integrationResp = result;
                this.data= data;
                
                //this.showNotification('Success', result.Message, 'success');
                console.log('this.date', JSON.stringify(this.data));
            }
            else {
                this.showDataTable = false;
                this.errorMessage = this.integrationResp.Message;
                this.displayError = true;
                //this.apiErrorMessage = this.integrationResp.Message;
                //this.showNotification('Error', result.Message, 'error');
            }
                console.log('respBody>>',JSON.parse(respBody));
                //console.log(JSON.parse(JSON.stringify(this.result)));
                
            })
            .catch(error => {
                this.isLoading = false;
                this.showDataTable = false;
                let errorDisplay = 'Error: ' + error.message;
                this.errorMessages = (error.body.message);
                this.errorMessages = this.result.StatusCode;
                console.error('Error object:', error);
                this.displayError = true;
               console.log('Error----> ' + JSON.stringify(error));
               
            });

}

connectedCallback(){
    this.fetchColumns();
}

fetchColumns() {
    getColumns({configName:'Abhi_FAdata_view'})
    .then(result => {
            console.log('result-->', result);
            this.columns = [
                
                ...result.map(col => ({
                    label: col.MasterLabel,
                    fieldName: col.Api_Name__c,
                    type: col.Data_Type__c,
                    cellAttributes: { alignment: 'left' }
                })),
            ];
            console.log('coloumns', JSON.stringify(this.columns));
            //this.GetFALevelDetails();
        })
    .catch(error => {

            
            this.showNotification('Error','Error fetching data.','Error');
            //this.showNotification('Error', 'Error fetching columns: ' + (error.body.message || error.message), 'error');
            console.log('Error fetching columns:', JSON.stringify(error));

        });
    
}

// Method to show notifications
showNotification(title, message, variant) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
    });
    this.dispatchEvent(event);
}

// get isEndDateDisabled() {
//     return !this.startDate;
// }

validateDates() {
    if (this.startDate && this.endDate) {
        const start = new Date(this.startDate);
        const end = new Date(this.endDate);

        if (end < start) {
            this.displayErrorSearch = true;
            this.errorMessageSearch= 'End Date cannot be earlier than Start Date.';
        } else {
            this.displayErrorSearch = false;
        }
    } else {
        this.displayErrorSearch = false; // Hide error if one of the dates is missing
    }
}

}