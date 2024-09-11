import { LightningElement, api, track, wire } from 'lwc';
import getViewClaimDetailsData from '@salesforce/apex/Abhi_ViewClaimDetails_Controller.viewClaimDetailsInformationCallout';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import claimDetails from '@salesforce/label/c.ABHI_Claim_Details_Header';
import { getRecord } from 'lightning/uiRecordApi';
import POLICY_NO_FIELD from '@salesforce/schema/Asset.Policy_No__c';

const fields = [POLICY_NO_FIELD];
export default class Abhi_ViewClaimDetails_LWC extends LightningElement {

    @api recordId;

    @track claimsData;

    showClaimDetailRecords = false;
    displayError;
    isLoading = false;

    policyNo = "";
    policyData;
    columns;

    label = {
        pageSize,
        claimDetails
    };

    @wire(getRecord, { recordId: "$recordId", fields })
    wiredPolicyRecord({ error, data }) {
        if (error) {
            this.displayError = true;
            let message = "Unknown error";
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(", ");
            } else if (typeof error.body.message === "string") {
                message = error.body.message;
            }
            console.log("Error inside wiredPolicyRecord " + message);

        } else if (data) {
            this.policyData = data;
            this.policyNo = this.policyData.fields.Policy_No__c.value;
            this.getColumnsData();
        }
    }

    getColumnsData() {

        this.isLoading = true;

        getColumns({ configName: 'ABHI_ClaimDetails' })
            .then(result => {
                this.columns = [
                    ...result.map(col => ({
                        label: col.MasterLabel,
                        fieldName: col.Api_Name__c,
                        type: col.Data_Type__c,
                        cellAttributes: { alignment: 'left' }
                    })),
                ];
                this.fetchViewClaimDetailsPolicy_Data();
            })
            .catch(error => {
                console.error('Error in getColumnsData>>>', error);
                this.isLoading = false;
            });
    }

    fetchViewClaimDetailsPolicy_Data() {

        getViewClaimDetailsData({policyNo: this.policyNo})
        .then(result => {

            this.isLoading = false;
            let statusCode = result?.StatusCode ?? "";
            
            if(statusCode === 1000) {
                this.claimsData = result?.Response;
            }
            else {
                this.displayError = `Error: ${result?.Message}`;
            }
        })
        .catch(error => {
            console.log('Error inside fetchViewClaimDetailsPolicy_Data ' + JSON.stringify(error));
            this.isLoading = false;
        });
    }

    handleRefresh() {
        this.isLoading = true;
        this.fetchViewClaimDetailsPolicy_Data();
    }
}