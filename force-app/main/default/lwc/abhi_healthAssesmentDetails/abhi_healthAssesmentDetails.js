import { LightningElement,track,api } from 'lwc';
import GetHealthDetails from '@salesforce/apex/ABHI_HealthAssesmentDetails.GetHealthDetails';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';

export default class Abhi_healthAssesmentDetails extends LightningElement {

    @api recordId;
    @track isLoading = false;
    @track errorMessages = '';
    @track displayError = false;
    @track showData;
    //@track pageSize = 7; // Number of records per page
    showRecords = false;
    policyNumber;
    @track columns = [];
@track data = [];

label = {
    errorMessage: 'Error in message',
    pageSize: 5
};


connectedCallback(){
    getColumns({configName:'ABHI_HealthAssesmentDetailsView'})
    .then(result => {
        console.log('result columns--'+JSON.stringify(result));
        this.columns = [
            ...result.map(col => ({
                label: col.MasterLabel,
                fieldName: col.Api_Name__c,
                type: col.Data_Type__c,
                cellAttributes: { alignment: 'left' },
            })),
        ]; 
        this.GetDetails();

    })
.catch(error => {
        
        this.isLoading=false;
        this.displayError=true;
        this.showRecords=false;
        console.error('error in Column fetch>>>', error);
    });
}

GetDetails(){
    this.isLoading = true;
    GetHealthDetails({assetId: this.recordId})
    .then(result => {
        console.log('Response Data:', JSON.stringify(result.Response));
        this.ApiFailure = result.Message; 
        if (result && result.Response !== undefined) { 
        if(result.StatusCode == 1000){     
        if (result.Response === null || !Array.isArray(result.Response) || result.Response.length === 0) {
                // Response is either null, not an array, or an empty array
                this.errorMessages = 'No data found';
                this.isLoading = false;
                this.displayError = true;
                this.showRecords = false;
            }else{
                // Response is a non-empty array
                this.displayError=false;
                this.data = result.Response;
                this.errorMessages = '';
                this.showRecords=true;
            }   
        }
        else if(result.StatusCode == 1001){
            this.errorMessages = result.Message;
            this.isLoading=false;
            this.displayError=true;
            this.showRecords=false;
        }
        else{
            this.message = result.Message;
            this.isLoading=false;
            this.displayError=true;
            this.showRecords=false;
        }
    }else {
            this.errorMessages = result.Message;
            console.log('error Messages>>>', this.errorMessages);
            this.displayError = true;
            this.showRecords = false;
        }
        this.isLoading = false;
    })
    .catch(error => {
        this.isLoading=false;
        this.displayError=true;
        this.showRecords=false;
        if (error.body!= null) {
            this.errorMessages = error.body.message;
        } else if(this.ApiFailure){
            this.errorMessages = this.ApiFailure;
        }
        else{
            this.errorMessages = 'An unknown error occured, please contact your system admin'
        }
        console.error('error in getdetails>>>', error);
    });
}

handleRefresh(){
    this.isLoading=true;
    this.showData=false;
    this.GetDetails();
}


}