import { LightningElement, track,api,wire } from 'lwc';
import getActiveDayEvents from '@salesforce/apex/ABHI_ActiveDayEventsController.getActiveDayEventsDetail';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CLIENT_CODE_FIELD from "@salesforce/schema/Account.Client_Code__c";
const fields = [CLIENT_CODE_FIELD];   
export default class Abhi_ActiveDayEventsDetail extends LightningElement {
    @api recordId;
    @track startDate = '';
    @track endDate = '';
    @track isLoading = false;
    @track disabled = false; // Adjust this as needed
    @track displayTable = false;
    @track displayError = false;
    @track errorMessages = '';
    @track showChildTable = false;
    @track apiName = '';
    @track payloadInfo = '';
    @track showDataTable = false; 
    @track displayError = false;
    pageSize = 10;
    columns;
    customerID;
    @track recordTable = []; 
    @track apiFailure ='';


    @wire(getRecord, { recordId: "$recordId", fields })
    wiredAccount(value) {
        if (value.data) {
            console.log('Account Data:', value.data);
            const clientCode = getFieldValue(value.data, CLIENT_CODE_FIELD);
            this.customerID = clientCode ? clientCode : null;
            this.handleApi();
        } else if (value.error) {
            console.error('Error fetching record:', value.error);
            this.isLoading = false;
            this.displayError = true;
            this.errorMessage = 'Error: ' + value.error.body.message;
        }
    }
    connectedCallback() {
        this.isLoading = true;
        this.displayError = false;
        console.log('recordId ',this.recordId);
    }
    handleApi() {
        this.isLoading = true;
        this.displayError = false;
        getActiveDayEvents({ 
            customerID: this.customerID, 
            accountId:this.recordId,
        })
        .then((result) => {
            this.isLoading = false;
            this.showDataTable = true;
            if(result.message){
                this.apiFailure=result.message;
            }
            if(result.serviceMessages[0].businessDesc==='Result found'){
                this.columnName(result);
            }
            else if (result.StatusCode ==1000 && result.serviceMessages[0].businessDesc!=null) {
                this.showDataTable = false;
                this.errorMessage = result.serviceMessages[0].businessDesc;
                this.displayError = true;

            }
            // Clear startDate and endDate fields
           // this.startDate = '';
            //this.endDate = '';     
           })
           .catch((error) => {
            console.log('Error----> ',JSON.stringify(error));
            this.isLoading = false;
            this.showDataTable = false;
            this.displayError = true;
            if ( error.body != null) {
                this.errorMessage =   error.body.message;
            } else if(this.apiFailure){
                this.errorMessage = this.apiFailure;
            }
            else{
                this.errorMessage = 'An unknown error occured, please contact your admin'
            }

        });
    }
    columnName(apiResponse) {
        getColumns({ configName: 'ABHI_ActiveDayEvents' })
        .then(result => {
            console.log('columns----> ' + JSON.stringify(result));
            this.columns = result.map(column => ({
                label: column.MasterLabel,
                fieldName: column.Api_Name__c,
                type: column.Data_Type__c,
            }));
            this.processResponse(apiResponse);
        })
        .catch(error => {
            console.error('Error fetching columns:',  JSON.stringify(error));
        });
    }
   
    processResponse(response) {
        console.log('operationStatus ', response);
        this.recordTable = []; // Initialize as an empty array
        if (response && response.operationStatus === 'SUCCESS' ) {
            const assessmentDetails = response.responseMap.resultsList.assessmentDetails; 
            if (assessmentDetails) {
                this.recordTable = assessmentDetails.map(detail => ({
                    totalActiveDayz: detail.totalActiveDayz,
                    avgCal: detail.avgCal,
                    avgSteps: detail.avgSteps,
                    avgGymVisits: detail.avgGymVisits,
                    totalCal: detail.totalCal,
                    totalSteps: detail.totalSteps,
                    totalGymVisits: detail.totalGymVisits
                }));
            } else {
                console.error('No assessment details found in the response.');
                this.error = 'No valid data available.';
            }
        } else {
            console.error('Operation status not SUCCESS or no response.');
            this.error = 'No valid response from API';
        }
    }    
    handleRefresh(){
       this.handleApi();
    }
}