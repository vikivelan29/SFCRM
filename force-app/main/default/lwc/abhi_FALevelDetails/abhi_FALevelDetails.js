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
    @track data;
    @track isLoading = false;
    @track errorMessages = '';
    @track displayError = false;
    


    get isSearchDisabled() {
        if (!this.startDate || !this.endDate) {
            return true; // Disable if either date is empty
        }        
        
  }

    showRecords = false;
    label = {
        errorMessage: 'Error in message',
        pageSize: 5
    };


    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleSearchClick() {
        

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
                console.log('insideIf');
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
                console.log('insideElse');

                this.showDataTable = false;
                this.errorMessages = this.result.Message;
                this.displayError = true;               
            }
                
            })
            .catch(error => {
                this.isLoading = false;
                this.showDataTable = false;
                let errorDisplay = 'Error: ' + error.message;
                this.errorMessages = (error.body.message);
                console.error('Error object:', error);
                this.displayError = true;
              
               
            });

}

connectedCallback(){
    this.fetchColumns();
}

fetchColumns() {
    getColumns({configName:'Abhi_FAdata_view'})
    .then(result => {
            console.log('**rec2>'+JSON.stringify(result));
            console.log('result1', result);
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

            
            //this.showNotification('Error','Error fetching data.','Error');
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

}