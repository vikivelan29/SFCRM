import { LightningElement,api,track } from 'lwc';
import GET_ViewInformationPolicyData from '@salesforce/apex/ABHI_ViewPolicyInformation_Controller.viewPolicyInformationApiCallout';

export default class Abhi_ViewPolicyInformation_LWC extends LightningElement {

    @api accRecId;

    @track policyData;

    isLoadingData = true;
    isHealthReturns = false;
    isAppRegistration = false;
    apiErrorMessage;
    healthAndAppRegError;
    
    connectedCallback() {
        this.fetchViewInformationPolicy_Data();
    }

    fetchViewInformationPolicy_Data() {

        GET_ViewInformationPolicyData({ accRecId: this.accRecId })
        .then(result => {

            this.isLoadingData = false;
            let respBody = result;
            let statusCode = result?.StatusCode ?? "";
            
            if(statusCode === 1000) {
                let summationOfTotalBalance = this.calculateTotalBalance(respBody, 'Total_Balance');
                this.policyData = {...respBody, totalBalance : summationOfTotalBalance};
                this.isAppRegistration = false;
                this.isHealthReturns   = false;
            }
            else if(statusCode === 1003) {
                this.apiErrorMessage = `Error: ${respBody?.Message}`;
                this.isAppRegistration = true;
                this.isHealthReturns   = true;
            }
            else {
                this.policyData = respBody;
                this.healthAndAppRegError = `Error: ${respBody?.Message}`;

                if(statusCode === 1001) {                   
                    let summationOfTotalBalance = this.calculateTotalBalance(respBody, 'Total_Balance');
                    this.policyData = {...respBody, totalBalance : summationOfTotalBalance};
                    this.isAppRegistration = true;
                    this.isHealthReturns   = false;
                }    
                else if(statusCode === 1002) {
                    this.isAppRegistration = false;
                    this.isHealthReturns   = true;
                }
                else {
                    this.apiErrorMessage = `Error: ${respBody?.Message}`;
                    this.policyData = null;
                }
            } 
            
        })
        .catch(error => {
            console.log('Error inside fetchViewInformationPolicy_Data ' + JSON.stringify(error));
            this.isLoadingData = false;
        });
    }

    calculateTotalBalance(respBody, sumByParticularKey) {

        let totalHealthReturnArray = respBody?.HealthReturns?.TotalHealthReturnObj;
        let totalBalance = totalHealthReturnArray.reduce((accumulator, currentValue) => {
            return Number(accumulator) + Number(currentValue[sumByParticularKey]);
        }, 0);

        return totalBalance;
    }

    refreshData() {
        this.policyData = null;
        this.apiErrorMessage = null;
        this.isLoadingData = true;
        this.fetchViewInformationPolicy_Data();
    }
} 