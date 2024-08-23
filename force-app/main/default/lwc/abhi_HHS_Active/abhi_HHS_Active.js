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

    customerId;

    @wire(getRecord, {
        recordId: "$recordId",
        fields
    })
    account;

    connectedCallback() {
        console.log('callBack called' );
        this.loadData();
    }

    loadData() {
        this.isLoading = true;
        this.displayError = false;
        // const clientCode = getFieldValue(this.account.data, CLIENT_CODE_FIELD);
        // this.customerID = clientCode ? clientCode : null;
        let customerId = this.recordId;
        console.log('recordId', this.recordId);

        getHhsActiveAge({customerId:customerId})
        .then(result => {
            console.log('result---->', result);
            this.isLoading = false;
            this.showDataTable = true;
            //result.serviceMessages[0].businessDesc === 'Result found'

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
        // Setup columns for the first data table
        getColumns({ configName: 'ABHI_HHS_ActiveAgeDetails' })
        .then(result => {
            console.log('result---->', result);
            this.columns = result.map(column => ({
                label: column.MasterLabel,
                fieldName: column.Api_Name__c,
                type: column.Data_Type__c,
                cellAttributes: { alignment: 'left' }
            }));
        })
        .catch(error => console.error('Error fetching columns:', error));

        // Setup columns for the second data table
        getColumns({ configName: 'ABHI_ActiveAgeDetails' })
        .then(result => {
            console.log('result---->', result);
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
            //this.recordTable = [];
            this.recordTable2 = tableData;  // Ensure this is populated as needed
        this.showDataTable = true;
        this.displayError = false;
            
            const resultsList = response.HHSDetails.responseMap.resultsList;
            const tableDate1 = [{
                tierLevelName:resultsList.tierLevelName
            }];
            this.recordTable = tableDate1;

        
            console.log('resultsList', resultsList);

            /*const activities = (resultsList.activities || []).map(activity => {
                console.log('activities', activities);
                // Process activity attributes into a key-value map
                const attributes = (activity.attributes || []).reduce((acc, attr) => {
                    console.log('attributes', attributes);
                    if (attr && attr.attributeCode && attr.attributeValue) {
                        acc[attr.attributeCode] = attr.attributeValue;
                    }
                    //acc[attr.attributeCode] = attr.attributeValue;
                    return acc;
                }, {});

                return {
                    Name: activity.name || '',
                    Code: activity.code || '',
                    Value: activity.value || '',
                    Score: activity.score || '',
                    EffFromDate: activity.effFromDate || '',
                    EffToDate: activity.effToDate || '',
                    ...attributes // Merge attributes into the activity object
                };
            });*/
            
            // Set the processed data for the second table
            //this.recordTable = activities;
            //this.showDataTable = true;
            //this.displayError = false;
        }else {
            //this.errorMessages = 'No valid response from API';
            this.errorMessages = response.Message || 'No valid response from API';
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