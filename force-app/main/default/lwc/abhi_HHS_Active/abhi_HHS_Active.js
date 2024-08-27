import { LightningElement, api, track, wire } from 'lwc';
import getHhsActiveAge from '@salesforce/apex/ABHI_HhsActiveAgeDetails_Controller.GetHhsActiveAge';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CLIENT_CODE_FIELD from "@salesforce/schema/Account.Client_Code__c";
const fields = [CLIENT_CODE_FIELD];

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
    @track noResultsMessage = false;

    customerId;

    @wire(getRecord, {
        recordId: "$recordId",
        fields
    })
    account;

    connectedCallback() {

        this.loadData();
    }

    loadData() {
        this.isLoading = true;
        this.displayError = false;
        // const clientCode = getFieldValue(this.account.data, CLIENT_CODE_FIELD);
        // this.customerID = clientCode ? clientCode : null;
        let customerId = this.recordId;

        getHhsActiveAge({customerId:customerId})
        .then(result => {
            console.log('result---->', result);
            this.isLoading = false;
            this.showDataTable = true;

            if(result.StatusCode == 1000) {
                this.setupColumns(result);
                this.processResponse(result);
            } else {
                this.showDataTable = false;
                this.errorMessages = result.Message;
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
                if (resultMessage.businessDesc === "Result found") {
                    // Check if responseMap and resultsList exist
                    if (response.HHSDetails.responseMap && response.HHSDetails.responseMap.resultsList) {
                        const resultsList = response.HHSDetails.responseMap.resultsList;
                        const tierLevelName = resultsList.tierLevelName;

                        // Ensure resultsList has activities
                        if (resultsList.activities && Array.isArray(resultsList.activities)) {
                            const activities = resultsList.activities;
                            console.log('activities-->', activities);

                            let table = [];
                            if (response.HHSDetails.operationStatus === 'SUCCESS') {
                                table.push({
                                    attributeCode: 'Current Score',
                                    attributeValue: tierLevelName
                                });
                                resultsList.activities.forEach(activity => {
                                    if (activity.attributes && Array.isArray(activity.attributes) && activity.attributes.length > 0) {
                                        activity.attributes.forEach(attr => {
                                            table.push({
                                                attributeCode: attr.attributeCode,
                                                attributeValue: attr.attributeValue
                                            });
                                        });
                                    }
                                });
                                this.table = table;
                                this.showTable = true;
                            } else {
                                this.table = [];
                                this.noResultsMessage = true;
                            }
                        } else {
                            // Handle case where activities are not present or not an array
                            this.table = [];
                            this.noResultsMessage = true;
                        }
                    } else {
                        this.noResultsMessage = true;
                    }
                } else if (resultMessage.businessDesc === "No Result found") {
                    // Handle case where "No Result found" is present
                    this.noResultsMessage = true;
                }
            } else {
                this.noResultsMessage = true;
            }
        } else {
            this.noResultsMessage = true;
        }
        }
        // Add tierLevelName and attributes to recordTable
        //this.recordTable = [attributeData]; 
             
        else {
            //this.errorMessages = 'No valid response from API';
            this.errorMessages = response.Message || 'No valid response recieved';
            this.displayError = true;
        }
    }

    formatNumber(value) {
        return Number(value).toLocaleString('en-US');
    }

    updateTableData() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        //this.recordTable2 = this.scoresList.slice(startIndex, endIndex);
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