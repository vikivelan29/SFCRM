import { LightningElement, api, track, wire } from 'lwc';
import getClaimDetails from '@salesforce/apex/ABCL_IntegrationCallout.executeCallout';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import claimDetails from '@salesforce/label/c.ABHI_Claim_Details_Header';
import { getRecord } from 'lightning/uiRecordApi';
import POLICY_NO_FIELD from '@salesforce/schema/Asset.Policy_No__c';
import BUSINESS_UNIT_FIELD from '@salesforce/schema/Asset.Business_Unit__c';
import { lanLabels } from 'c/asf_ConstantUtility';

const fields = [POLICY_NO_FIELD, BUSINESS_UNIT_FIELD];
export default class Abhi_ViewClaimDetails_LWC extends LightningElement {

    @api recordId;

    @track claimsData;

    showClaimDetailRecords = false;
    displayError = false;
    isLoading = false;

    displayMessage = "";
    policyNo = "";
    businessUnit = "";
    policyData;

    label = {
        pageSize,
        claimDetails
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
            console.log("Error inside wiredPolicyRecord " + message);

        } else if (data) {
            this.policyData = data;
            this.policyNo = this.policyData.fields.Policy_No__c.value;
            this.businessUnit = this.policyData.fields.Business_Unit__c.value
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
                this.getData();
            })
            .catch(error => {
                console.error('Error in getColumnsData>>>', error);
                this.isLoading = false;
            });
    }

    getData() {

        let reqBody = {"RequestType" : "ClaimMasterDetails", "PolicyNumber" : this.policyNo};

        getClaimDetails({requestBody : JSON.stringify(reqBody), integrationName : 'ABHI_View_Claim_Details_API_Details'})
            .then(result => {

                let responseBody = JSON.parse(result?.responseBody) ?? "";
                let statusCode = responseBody?.StatusCode;

                if (statusCode === 1000) {
                    this.isLoading = false;
                    this.displayError = false;
                    let claimsData = responseBody?.Response;

                    if (claimsData) {
                        this.claimsData = claimsData;
                        this.showClaimDetailRecords = true;
                    }
                    else {
                        this.displayMessage = lanLabels[this.businessUnit].CLAIMDETAILS_FAILURE_MESSAGE;
                    }
                }
                else {
                    this.displayMessage = `Error: ${responseBody.Message}`;
                    this.isLoading = false;
                    this.showClaimDetailRecords = false;
                    this.displayError = true;
                }
            })
            .catch(error => {
                this.displayMessage = 'Error : ' + error.body.message;
                this.isLoading = false;
                this.showClaimDetailRecords = false;
                this.displayError = true;
                console.error('error in getClaimDetails>>>', JSON.stringify(error));
            });
    }

    handleRefresh() {
        this.isLoading = true;
        this.getData();
    }
}