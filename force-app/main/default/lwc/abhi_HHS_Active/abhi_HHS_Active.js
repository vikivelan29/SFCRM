import { LightningElement, api, track, wire } from 'lwc';
import getHhsActiveAge from '@salesforce/apex/ABHI_HhsActiveAgeDetails_Controller.GetHhsActiveAge';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CLIENT_CODE_FIELD from "@salesforce/schema/Account.Client_Code__c";
const fields = [CLIENT_CODE_FIELD];
const ATTRIBUTE_CODE_LABELS = {
    'DIABTS': 'Fasting Blood Sugar (mg/dl)',
    'TOTCHL': 'Total Cholesterol',
    'SMOKER': 'Smoking Status',
    'DIASTOLIC': 'Diastolic',
    'BPMDIA': 'Diastolic',
    'BPMSYS': 'Systolic',
    'BPMSYS': 'Systolic',
    'tierLevelName': 'Current Score',
    'AGE': 'Age'
};
const ALLOWED_ATTRIBUTES = [
    'Smoking Status',
    'Diastolic',
    'Systolic',
    //'Age'
];
const DEFAULT_VALUES = {
    'Fasting Blood Sugar (mg/dl)': '0',
    'Total Cholesterol': '0',
    'Smoking Status': '0',
    'Diastolic': '0',
    'Systolic': '0',
    'Current Score': '0',
    'Age': '0'
};

export default class AbhiActiveAgeDetails extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track displayError = false;
    @track errorMessages = '';
    @track showDataTable = false; 
    @track recordTable = [];
    @track recordTable2 = [];
    @track columns = [];
    @track columns2 = [];
    @track currentPage = 1;
    @track pageSize = 7; // Number of records per page
    @track totalRecords = 0;
    @track totalPages = 0;
    @track scoresList = [];
    @track showTable = false; 
    @track tableData = [];

    customerId;

    get showResultMessage() {
        return this.resultMessageValue && !this.displayError;
    }

    @wire(getRecord, {
        recordId: "$recordId",
        fields
    })
    account;

    connectedCallback() {

        this.loadData();
    }

    initializeTable() {
        this.table = Object.keys(DEFAULT_VALUES).map(label => ({
            attributeCode: label,
            attributeValue: DEFAULT_VALUES[label]
        }));
        //console.log('Initialized Table with Defaults:', JSON.stringify(this.table, null, 2));

    }

    loadData() {
        this.isLoading = true;
        this.displayError = false;
        let customerId = this.recordId;

        getHhsActiveAge({customerId:customerId})
        .then(result => {
            this.isLoading = false;
            this.showDataTable = true;

            if(result.StatusCode == 1000 && Object.keys(result.HHSDetails.responseMap).length > 0) {
                this.setupColumns(result);
                this.processResponse(result);
            } else if (result.StatusCode == 1000 && Object.keys(result.HHSDetails.responseMap).length ===0){
                this.setupColumns(result);
                this.processResponse(result);
                this.resultMessageValue = result.HHSDetails.serviceMessages[0].businessDesc;

            } else if (result.StatusCode == 1002 && Object.keys(result.HHSDetails.responseMap).length > 0){
                this.showDataTable = false;
                this.errorMessages = result.Message;
                this.displayError = true;
                this.showTable = true;
                this.processResponse(result);

            }
            else {
                this.showDataTable = false;
                this.errorMessages = result.Message;
                this.resultMessageValue = result.HHSDetails.serviceMessages[0].businessDesc;
                this.displayError = true;
            
            }
            
        })
        .catch(error => {
            this.isLoading = false;
            this.displayError = true;
            if (error.body!= null) {
                this.errorMessages = error.body.message;
                this.resultMessageValue = error.body.message;
            } else if(this.ApiFailure){
                this.errorMessages = this.ApiFailure;
                this.resultMessageValue = this.ApiFailure;
                
            }
            else{
                this.errorMessages = 'An unknown error occured, please contact your system admin'
                this.resultMessageValue = this.errorMessages;
            }
        });
    }

    setupColumns(apiResponse) {
        // // Setup columns for the first data table
        // getColumns({ configName: 'ABHI_HHS_ActiveAgeDetails' })
        // .then(result => {
        //     console.log('result---->', result);
        //     this.columns = result.map(column => ({
        //         label: column.MasterLabel,
        //         fieldName: column.Api_Name__c,
        //         type: column.Data_Type__c,
        //         cellAttributes: { alignment: 'left' }
        //     }));
        // })
        //.catch(error => console.error('Error fetching columns:', error));

        // Setup columns for the second data table
        getColumns({ configName: 'ABHI_ActiveAgeDetails' })
        .then(result => {
            console.log('result---->', result);
            this.columns2 = result.map(column => ({
                label: column.MasterLabel,
                fieldName: column.Api_Name__c,
                type: column.Data_Type__c,
                cellAttributes: { alignment: 'left' }
            }));
        })
        .catch(error => console.error('Error fetching columns:', error));
    }

    processResponse(response) {
        console.log('API Response:', response);
        this.recordTable = null;
        this.recordTable2 = [];
        this.currentPage = 1;
        let hasData = false;
        
        if (response && response.StatusCode === '1000'|| response.StatusCode === '1002') {
            //console.log('response code', response.StatusCode);
          
            if(response.activeAge!=null){
                const activeAge = response.activeAge;

            const tableData = [{
                CustomerNo: activeAge.CustomerNo,
                ActualAge: activeAge.ActualAge,
                MultiplyAge: activeAge.MultiplyAge,
                HeartAge: activeAge.HeartAge,
                CalculationDate: activeAge.CalculationDate
            }];
            this.recordTable2 = tableData;  // Ensure this is populated as needed
            this.showDataTable = true;
            this.displayError = false;
            hasData = true;
        }
        else{
            this.showDataTable = false;
            this.displayError = true;
            this.errorMessages = response.Message;
        }
           // Check if HHSDetails and serviceMessages exist
        if (response.HHSDetails && Array.isArray(response.HHSDetails.serviceMessages)) {
            const serviceMessages = response.HHSDetails.serviceMessages;

            // Find if there is a message with "Result found" or "No Result found"
            const resultMessage = serviceMessages.find(msg =>
                msg.businessDesc === "Result found" || msg.businessDesc === "No Result found"
            );
            
            const resultsList = response.HHSDetails.responseMap.resultsList;
            const activities = resultsList.activities;
            console.log('activities-->',activities);

            let table = [];
            if (activities && activities.length > 0) {
                activities.forEach(activity => {
                    if (activity.attributes && activity.attributes.length > 0) {
                        let row = { tierLevelName: resultsList.tierLevelName }; 
                        activity.attributes.forEach(attr => {
                            table.push({
                                name: attr.attributeCode,
                                value: attr.attributeValue
                            });
                        });
                    }
                });
            }
            console.log('Processed Table Data:', tableData);
        this.table = table;
        console.log('this.table', this.table);
        this.showTable = true;
        this.displayError = false;
        

        // Add tierLevelName and attributes to recordTable
        //this.recordTable = [attributeData]; 
             
        }else {
            //this.errorMessages = 'No valid response from API';
            this.errorMessages = response.Message;
            this.displayError = true;
        }
        if (!hasData) {
            this.showDataTable = false;
            this.displayError = true; 
            
        }
    
    }

    formatNumber(value) {
        return Number(value).toLocaleString('en-US');
    }

    updateTableData() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        
    }

    handleRefresh() {
        this.loadData();
    }

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
}