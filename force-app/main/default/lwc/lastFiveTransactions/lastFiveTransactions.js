/* eslint-disable eqeqeq */
/* eslint-disable no-empty */
/* eslint-disable no-unused-vars */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASEINT_ID from "@salesforce/schema/ASF_Case_Integration__c.Id";
import CASEINT_RESPONSE from "@salesforce/schema/ASF_Case_Integration__c.Response__c";
import CASEINT_STATUS from '@salesforce/schema/ASF_Case_Integration__c.Status__c';

export default class LastFiveTransactions extends LightningElement {

    @api caseIntId;
    integrationResponse;

    @wire(getRecord, {
        recordId: "$caseIntId",
        fields: [CASEINT_ID, CASEINT_RESPONSE, CASEINT_STATUS]
    })
    wiredCaseIntegrationRecord({ error, data }) {
        if (data) {
            console.log('TEST');
            if(getFieldValue(data, CASEINT_STATUS) == 'Success'){
                this.integrationResponse = JSON.parse(getFieldValue(data, CASEINT_RESPONSE));
                console.log(this.integrationResponse);
            }
        }
        else if (error) {
          
        }
    }

}