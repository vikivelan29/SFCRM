import { LightningElement, api, wire, track } from 'lwc';
import getHealthReturnData from '@salesforce/apex/Abhi_HealthReturnController.healthReturnCallout';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import healthReturnHeader from '@salesforce/label/c.ABHI_Health_Return_Header';
import healthReturnViewTitle from '@salesforce/label/c.ABHI_Health_Return_View';
import { getRecord } from 'lightning/uiRecordApi';
import POLICY_NO_FIELD from '@salesforce/schema/Asset.Policy_No__c';
import PROPOSAL_NO_FIELD from '@salesforce/schema/Asset.SerialNumber';

const fields = [POLICY_NO_FIELD, PROPOSAL_NO_FIELD];

export default class Abhi_HealthReturnDetails extends LightningElement {

    @api recordId;

    @track columns;
    @track healthReturnData;
    @track healthReturnFormData = {};
    healthReturnColumns;
    @track healthReturnAggData=[];

    displayError;
    isLoading = false;
    showTitle = false;

    policyNo = "";
    proposalNo = "";
    policyData = [];

    label = {
        pageSize,
        healthReturnHeader,
        healthReturnViewTitle
    };

    @wire(getRecord, { recordId: "$recordId", fields })
    wiredPolicyRecord({ error, data }) {
        if (error) {
            let message = "Unknown error";
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(", ");
            } else if (typeof error.body.message === "string") {
                message = error.body.message;
            }
            this.displayError = message;
            this.showTitle = true;

        } else if (data) {
            this.displayError = "";
            this.policyData = data;
            this.policyNo = this.policyData.fields.Policy_No__c.value;
            this.proposalNo = this.policyData.fields.SerialNumber.value;
            this.getColumnsData();
        }
    }

    getColumnsData() {

        this.isLoading = true;

        getColumns({ configName: 'ABHI_HealthReturnDetails' })
            .then(result => {
                this.columns = [
                    ...result.map(col => ({
                        label: col.MasterLabel,
                        fieldName: col.Api_Name__c,
                        type: col.Data_Type__c,
                        cellAttributes: { alignment: 'left' }
                    })),
                ];
                this.getAggregateColumns();
            })
            .catch(error => {
                console.error('Error in getColumnsData>>>', error);
                this.displayError = `Error: ${JSON.stringify(error)}`;
                this.isLoading = false;
                this.showTitle = true;
            });
        
    }

    getAggregateColumns(){
        getColumns({ configName: 'ABHI_HealthReturnAggregateDetails' })
            .then(result => {
                this.healthReturnColumns = [
                    ...result.map(col => ({
                        label: col.MasterLabel,
                        fieldName: col.Api_Name__c,
                        type: col.Data_Type__c,
                        cellAttributes: { alignment: 'left' }
                    })),
                ];
                this.fetchHealthReturn_Data();
            })
            .catch(error => {
                console.error('Error in getColumnsData>>>', error);
                this.displayError = `Error: ${JSON.stringify(error)}`;
                this.isLoading = false;
                this.showTitle = true;
            });
    }

    fetchHealthReturn_Data() {

        getHealthReturnData({ policyNo: this.policyNo, proposalNo: this.proposalNo })
            .then(result => {

                this.isLoading = false;
                this.showTitle = true;

                let statusCode = result?.StatusCode ?? "";

                if (statusCode === 1000) {
                    this.displayError = "";
                    this.healthReturnData = result?.Response;
                    this.healthReturnAggData = this.initHealthReturnFormData();
                }
                else {
                    this.displayError = `Error: ${result?.Message}`;
                    this.healthReturnData = false;
                }
            })
            .catch(error => {
                this.isLoading = false;
                this.showTitle = true;
                this.healthReturnData = false;
                this.displayError = `Error: ${JSON.stringify(error)}`;
            });
    }

    initHealthReturnFormData() {

        let recordArr = [];
        let memberArr = [];
        for (let record of this.healthReturnData) {
            
            if(memberArr.includes(record.vchClientCode)){
                recordArr.forEach(element => {
                    if(element.vchClientCode == record.vchClientCode){
                        element.TotalActiveDays = (element.TotalActiveDays || 0) + parseInt(record.ActiveDays);
                        element.TotalHealthReturnsTMEarned = (element.TotalHealthReturnsTMEarned || 0) + parseFloat(record.TotalHealthReturnsTMEarned);
                        element.TotalHealthReturnsTMBurnt = (element.TotalHealthReturnsTMBurnt || 0) + parseFloat(record.TotalHealthReturnsTMBurnt);
                        const difference = parseFloat(record.TotalHealthReturnsTMEarned) - parseFloat(record.TotalHealthReturnsTMBurnt);
                        element.BalanceHealthReturns = (element.BalanceHealthReturns || 0) + difference;
                    }
                });
            }
            else{
                recordArr.push({
                    "TotalActiveDays": parseInt(record.ActiveDays),
                    "vchClientCode": record.vchClientCode,
                    "Name": record.Name,
                    "TotalHealthReturnsTMEarned": parseFloat(record.TotalHealthReturnsTMEarned),
                    "TotalHealthReturnsTMBurnt": parseFloat(record.TotalHealthReturnsTMBurnt),
                    "BalanceHealthReturns": parseFloat(record.TotalHealthReturnsTMEarned) - parseFloat(record.TotalHealthReturnsTMBurnt)
                });
                memberArr.push(record.vchClientCode);
            }
        }
        return recordArr;
    }

    handleRefresh() {
        this.isLoading = true;
        this.fetchHealthReturn_Data();
    }
}