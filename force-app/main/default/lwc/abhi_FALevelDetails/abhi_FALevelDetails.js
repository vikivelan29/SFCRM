import { LightningElement, api, track } from 'lwc';
import GetFALevelDetails from '@salesforce/apex/ABHI_FALevelDetails_Controller.GetFALevelDetails';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
//import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import styles from '@salesforce/resourceUrl/ASF_RemoveDateFormatStyle';

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
    @track errorMessageSearch ='';
    @track ApiFailure = '';
    
    


    get isSearchDisabled() {
        if (!this.startDate || !this.endDate) {
            return true; // Disable if either date is empty
        }
        //return new Date(this.startDate) > new Date(this.endDate); // Disable if start date is greater than end date
        const start = new Date(this.startDate);
        const end = new Date(this.endDate);
        return end < start; 
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
    handleRefresh(){
        this.handleSearchClick();
    }


    handleSearchClick() {
        

        if (this.isSearchDisabled) {
            return; // Prevent search if invalid
        }
        this.isLoading = true;
        this.displayError = false; 
        this.errorMessages = '';
    

        GetFALevelDetails({ customerId: this.recordId, fromDate: this.startDate, toDate: this.endDate })
            .then(result => {
                this.isLoading = false;
                this.displayTable=false;
                this.result = result;
            console.log('result' ,result);
            let StatusCode = result.StatusCode;
            console.log('StatusCode', result.StatusCode);
            this.ApiFailure = result.Message;

            if(StatusCode == 1000) {
                this.displayTable=true;
                this.showRecords=true;
                let data = [];
                data.push(result);
                this.data= data;
                this.errorMessages = '';
                this.displayError = false;
            }else if (this.statusCode === 1001) {
                // Handle 1001 Status Code
                this.displayTable = false;
                this.showRecords = false;
                this.errorMessages = result.Message;
                this.displayError = true;
            }else if (this.statusCode === 204) {
                // Handle 204 No Content
                this.displayTable = false;
                this.showRecords = false;
                this.errorMessages = 'No content available';
                this.displayError = true;
            }
            else {
                this.showDataTable = false;
                this.errorMessages = result.Message;
                this.displayError = true;
                console.log('errorMessages>>' ,this.result.Message);
               
            }
                
            })
            .catch(error => {
                this.isLoading = false;
                this.showDataTable = false;
                //let errorDisplay = 'Error: ' + error.message;
                //this.errorMessages = (error.body.message);
                this.displayError = true;
                if (error.body!= null) {
                    this.errorMessages = error.body.message;
                } else if(this.ApiFailure){
                    this.errorMessages = this.ApiFailure;
                }
                else{
                    this.errorMessages = 'An unknown error occured, please contact your system admin'
                }
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
        })
    .catch(error => {
            console.log('Error fetching columns:', JSON.stringify(error));

        });
    
}

// Method to show notifications
// showNotification(title, message, variant) {
//     const event = new ShowToastEvent({
//         title: title,
//         message: message,
//         variant: variant,
//     });
//     this.dispatchEvent(event);
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
renderedCallback(){
    Promise.all([
        loadStyle(this, styles) //specified filename
    ]).then(() => {
        console.log('Files loaded.');
    }).catch(error => {
       console.log("Error " + error.body.message);
    });
}

}