import { LightningElement, api, track, wire } from 'lwc';
import getActiveDaysDashboard from '@salesforce/apex/ABHI_ActiveDaysDashboardController.getActiveDaysDashboard';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CLIENT_CODE_FIELD from "@salesforce/schema/Account.Client_Code__c";
const fields = [CLIENT_CODE_FIELD];   
export default class Abhil_ActiveDaysDashboard extends LightningElement {
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
    @track errorDisplay='';
    columns;
    columns2;
    @track recordTable = []; 
    @track recordTable2 = []; 
    @track currentPage = 1;
    @track pageSize = 7; // Number of records per page
    @track totalRecords = 0;
    @track totalPages = 0;
    @track scoresList = []; // Store the 
    customerID;
    @api recordId;

    @wire(getRecord, {
        recordId: "$recordId",
        fields
      })
    account;
    get isSearchDisabled() {
        if (!this.startDate || !this.endDate) {
            return true; // Disable if either date is empty
        }        
        const start = new Date(this.startDate);
        const end = new Date(this.endDate);
        return end < start; 
  }
    // Event handler for the start date change
    handleStartDateChange(event) {
        this.startDate = event.target.value;
        console.log('startdate ',this.startDate);
        this.validateDates();
    }
    

    // Event handler for the end date change
    handleEndDateChange(event) {
        this.endDate = event.target.value;
        console.log('startdate ',this.endDate);
        this.validateDates();

    }

    // Event handler for the search button
    handleSearch() {
        if (this.isSearchDisabled) {
            return; // Prevent search if invalid
        }
        this.isLoading = true;
        this.displayError = false;
        const clientCode = getFieldValue(this.account.data, CLIENT_CODE_FIELD);
        console.log('clientCode ',clientCode);
        this.customerID = clientCode ? clientCode : null;
        getActiveDaysDashboard({ 
            customerID: this.customerID, 
            accountId:this.recordId,
            fromDate: this.startDate, 
            toDate: this.endDate 
        })
        .then((result) => {
            this.isLoading = false;
            this.showDataTable = true;
            if(result.serviceMessages[0].businessDesc==='Has active dayz'){
                this.columnName(result);
                this.columnName2();
            }
            else if (result.serviceMessages[0].businessDesc!=null) {
                this.showDataTable = false;
                this.errorMessage = result.serviceMessages[0].businessDesc;
                this.displayError = true;
            }
           /* this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Response is recieved successfully',
                    variant: 'success',
                })
            );*/
            // Clear startDate and endDate fields
           // this.startDate = '';
            //this.endDate = '';     
           })
        .catch((error) => {
            this.isLoading = false;
            this.showDataTable = false;
            this.errorDisplay = 'Error: ' + error.body.message;
            this.showDataTable = false;
            this.errorMessage =   error.body.message;
            this.displayError = true;
           console.log('Error----> ' + JSON.stringify(error));

        });
    }
   columnName(apiResponse) {
        getColumns({ configName: 'ABHI_ActivedaysDashboard' })
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
            console.error('Error fetching columns:', error);
        });
    }
    columnName2() {
        getColumns({ configName: 'ABHI_ActivedaysActivity' })
        .then(result => {
            console.log('columns----> ' + JSON.stringify(result));
            this.columns2 = result.map(column => ({
                label: column.MasterLabel,
                fieldName: column.Api_Name__c,
                type: column.Data_Type__c,
            }));
        })
        .catch(error => {
            console.error('Error fetching columns:', error);
        });
    }
    processResponse(response) {
        console.log('operationStatus ',response);
        this.recordTable = null;
        this.recordTable2 = [];
        this.currentPage = 1;
        if (response && response.operationStatus === 'SUCCESS' ) {
            console.log('businessDesc ', response.serviceMessages[0].businessDesc);
            //const dateObj = new Date(resultsList.scores[0].activeDate);
            //this.formattedDate = dateObj.toISOString().split('T')[0];
            const resultsList = response.responseMap.resultsList;
            console.log('resultsList ',resultsList.totalScoreForPeriod);
            const tableData = [{
                totalScoreForCalories: resultsList.totalScoreForCalories,
                totalScoreForGym: resultsList.totalScoreForGym,
                totalScoreForSteps: resultsList.totalScoreForSteps,
                totalScoreForPeriod: resultsList.totalScoreForPeriod,
            }];
            const scoresList = resultsList.scores;

            this.scoresList = scoresList.flatMap(score => 
                score.activities.map(activity => ({
                    //eventDate: score.activeDate,
                    eventDate: new Date(score.activeDate).toISOString().split('T')[0],
                    isScored: score.isScored === 'true' ? "True" : "False",
                    caloriesActivity: activity.name === "Calories Activity" ? this.formatNumber(activity.value || 0) : '',
                    Steps_Activity: activity.name === "Step Activity" ? this.formatNumber(activity.value || 0) : '',
                    gymActivity: activity.name === "Gym Activity" ? this.formatNumber(activity.value || 0) : '',
                    Score: this.formatNumber(activity.score || 0)
                }))
            );    
            this.totalRecords = this.scoresList.length;
            this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
            this.updateTableData();
            this.error = null;
            this.recordTable=tableData;
        } else {
            this.error = 'No valid response from API';
        }
    }
    handleRefresh(){
        this.handleSearch();
    }
    formatNumber(value) {
        return Number(value).toLocaleString('en-US');
    }
     // Updating table data based on current page
     updateTableData() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        this.recordTable2 = this.scoresList.slice(startIndex, endIndex);
    }

    // Starts pagination controls
    firstPage() {
        this.currentPage = 1;
        this.updateTableData();
    }

    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.updateTableData();
        }
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.updateTableData();
        }
    }

    lastPage() {
        this.currentPage = this.totalPages;
        this.updateTableData();
    }

    get bDisableFirst() {
        return this.currentPage === 1;
    }

    get bDisableLast() {
        return this.currentPage === this.totalPages;
    }

    get pageNumber() {
        return this.currentPage;
    }
    validateDates() {
        if (this.startDate && this.endDate) {
            const start = new Date(this.startDate);
            const end = new Date(this.endDate);

            if (end < start) {
                this.displayError = true;
                this.errorMessage= 'End Date cannot be earlier than Start Date.';
            } else {
                this.displayError = false;
            }
        } else {
            this.displayError = false; // Hide error if one of the dates is missing
        }
    }

}