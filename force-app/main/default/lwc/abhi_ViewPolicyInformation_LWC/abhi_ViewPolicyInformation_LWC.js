import { LightningElement,api,track } from 'lwc';
import GET_ViewInformationPolicyData from '@salesforce/apex/ABHI_ViewPolicyInformation_Controller.viewPolicyInformationApiCallout';

export default class Abhi_ViewPolicyInformation_LWC extends LightningElement {

    @api accRecId;

    @track policyData;

    apiErrorMessage;
    
    connectedCallback() {
        this.fetchViewInformationPolicy_Data();
    }

    fetchViewInformationPolicy_Data() {

        GET_ViewInformationPolicyData({ accRecId: this.accRecId })
        .then(result => {

            let respString = result.responseBody;
            let statusCode = result.statusCode;
            let respBody = JSON.parse(respString);
            
            if(statusCode === 1000) {
                let summationOfTotalBalance = this.calculateTotalBalance(respBody, 'Total_Balance');
                this.policyData = {...respBody, totalBalance : summationOfTotalBalance};
            }
            else {
                this.apiErrorMessage = `Error: ${respBody?.Message ?? respBody?.message}`;
            }
        })
        .catch(error => {
            console.log('Error inside fetchViewInformationPolicy_Data ' + JSON.stringify(error));
        });
    }

    calculateTotalBalance(respBody, sumByParticularKey) {

        let totalHealthReturnArray = respBody?.HealthReturns?.TotalHealthReturnObj;
        let totalBalance = totalHealthReturnArray.reduce((accumulator, currentValue) => {
            return Number(accumulator) + Number(currentValue[sumByParticularKey]);
        }, 0);

        return totalBalance;
    }
}