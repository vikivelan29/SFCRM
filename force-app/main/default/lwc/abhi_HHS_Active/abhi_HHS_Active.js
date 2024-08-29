import { LightningElement, api, track, wire } from 'lwc';
import getHhsActiveAge from '@salesforce/apex/ABHI_HhsActiveAgeDetails_Controller.GetHhsActiveAge';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CLIENT_CODE_FIELD from "@salesforce/schema/Account.Client_Code__c";
const fields = [CLIENT_CODE_FIELD];
const ATTRIBUTE_CODE_LABELS = {
    'DIABTS': 'Fasting Blood Sugar (mg/dl)',
    'TOTCHL': 'Total Cholesterol',
    'SMOKING STATUS': 'Smoking Status',
    'DIASTOLIC': 'Diastolic',
    'SYSTOLIC': 'Systolic',
    'AGE': 'Age'
};
const ALLOWED_ATTRIBUTES = [
    'Current Score',
    'Fasting Blood Sugar mgdl',
    'Total Cholesterol',
    'Smoking Status',
    'Diastolic',
    'Systolic',
    'Age'
];

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
    @track noResultsMessage = false;
    resultMessageValue;

    handleUploadStart() {
        this.isLoading = true;
        this.displayError = false;
        let customerId = this.recordId;

        getHhsActiveAge({customerId:customerId})
        .then(result => {
            console.log('result---->', result);
            this.isLoading = false;
            this.showDataTable = true;

            if(result.StatusCode == 1000 && result.HHSDetails.serviceMessages[0].businessDesc==="Result found") {
                this.setupColumns(result);
                this.processResponse(result);
            } else if (result.StatusCode == 1000 && result.HHSDetails.serviceMessages[0].businessDesc==="No Result found"){
                this.setupColumns(result);
                this.processResponse(result);
                this.resultMessageValue = result.HHSDetails.serviceMessages[0].businessDesc;

            } else if (result.StatusCode == 1002 && result.HHSDetails.serviceMessages[0].businessDesc==="Result found"){
                this.showDataTable = false;
                this.errorMessages = result.Message;
                this.resultMessageValue = "No Result found";
                this.displayError = true;

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
            this.errorMessages = error.body.message;
        });
    }

    setupColumns(apiResponse) {
        
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
        
        if (response && response.StatusCode === '1000') {
          

            // console.log('response.operationStatus', response.operationStatus);
            ///const resultsList = response.activeAge;
                const activeAge = response.activeAge;
            console.log('activeAge-->',activeAge);

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
        
            
           // Check if HHSDetails and serviceMessages exist
        if (response.HHSDetails && Array.isArray(response.HHSDetails.serviceMessages)) {
            const serviceMessages = response.HHSDetails.serviceMessages;

            // Find if there is a message with "Result found" or "No Result found"
            const resultMessage = serviceMessages.find(msg =>
                msg.businessDesc === "Result found" || msg.businessDesc === "No Result found"
            );
            

            
            if (resultMessage) {
                if (resultMessage.businessDesc === "Result found" && response.HHSDetails.responseMap && Object.keys(response.HHSDetails.responseMap).length > 0) {
                
                        const resultsList = response.HHSDetails.responseMap.resultsList;
                        const tierLevelName = resultsList.tierLevelName;
                        const activities = resultsList.activities;
                        
                        console.log('valuss---', ATTRIBUTE_CODE_LABELS);

                            console.log('activities-->', activities);
                            console.log('Activities:', JSON.stringify(activities, null, 2));

                            let table = [];
                            if (response.HHSDetails.operationStatus === 'SUCCESS') {
                                table.push({
                                    attributeCode: 'Current Score',
                                    attributeValue: tierLevelName || ''
                                });


                                let attributeValues = {
                                    'Total Cholesterol': '',
                                    'Fasting Blood Sugar (mg/dl)': ''
                                };

                                // let totalCholesterolFound = false;
                                // let fastingBloodSugarFound = false;

                                activities.forEach(activity => {
                                    if (activity.name === "Total cholesterol") {
                                        attributeValues['Total Cholesterol'] = activity.value || '';
                                    } else if (activity.name === "Fasting Blood Sugar (mg/dl)") {
                                        attributeValues['Fasting Blood Sugar (mg/dl)'] = activity.value || '';
                                    }
                                    if (activity.attributes && Array.isArray(activity.attributes) && activity.attributes.length > 0) {
                                        activity.attributes.forEach(attr => {
                                            const label = ATTRIBUTE_CODE_LABELS[attr.attributeCode] || attr.attributeCode;
                                            if (ALLOWED_ATTRIBUTES.includes(label)) {
                                                table.push({
                                                    attributeCode: label,
                                                    attributeValue: attr.attributeValue || ''
                                                });
                                            }
                                        });
                                    }
                                });
        
                                // Add specific attributes to the table
                                Object.keys(attributeValues).forEach(key => {
                                    table.push({
                                        attributeCode: key,
                                        attributeValue: attributeValues[key]
                                    });
                                });
        
                                this.table = table;
                                console.log('Table Data:', JSON.stringify(this.table, null, 2));
                                this.showTable = true;
                            } else {
                                this.table = [];
                                this.noResultsMessage = true;
                            }
                   
                } else if (resultMessage.businessDesc === "No Result found") {
                    // Handle case where "No Result found" is present
                    this.noResultsMessage = resultMessage.businessDesc;
                }
            } else {
                this.noResultsMessage = resultMessage.businessDesc;
            }
        } else {
            this.noResultsMessage = true;
        }
        } else {
            //this.errorMessages = 'No valid response from API';
            this.errorMessages = response.Message;
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