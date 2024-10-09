import { LightningElement,wire,api,track } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import ACCOUNT_RECORDTYPE from '@salesforce/schema/Opportunity.Account.RecordType.DeveloperName';  
import POLICY_RECORD_ID_FIELD from "@salesforce/schema/Opportunity.Policy__c";
import PROPOSAL_No_FIELD from "@salesforce/schema/Opportunity.Policy__r.SerialNumber";
import POLICY_ID_FIELD from "@salesforce/schema/Opportunity.Policy__r.ABHI_Policy_Id__c";
  
import getAPIResponse from '@salesforce/apex/RNWL_MemberDetailsController.getAPIResponse';

const fields = [ACCOUNT_RECORDTYPE, POLICY_RECORD_ID_FIELD, POLICY_ID_FIELD, PROPOSAL_No_FIELD];

const columns = [
    { label: 'Name', fieldName: 'Name',wrapText: true },
    { label: 'Member Id', fieldName: 'Member ID', wrapText: true  },
    { label: 'Membership Relationship', fieldName: 'Membership Relationship', wrapText: true },
    { label: 'Member DOB', fieldName: 'Member DOB',wrapText: true  },
    { label: 'HA', fieldName: 'HA', wrapText: true }, 
    { label: 'FA', fieldName: 'FA', wrapText: true }, 
    { label: 'DHA', fieldName: 'DHA', wrapText: true }, 
    { label: 'AHC', fieldName: 'AHC', wrapText: true }
     
];  
 
export default class RNWL_GetRenewalDetails extends LightningElement {
    @api recordId;
    @track data;
    @track error;  
    lstAPINames;
    isIndividalAccount = false;
    policyId;
    policyNumber;
    proposalNo;
    columns = columns; 
     
    @wire(getRecord, { recordId: '$recordId', fields }) 
    record({ error, data }){
        if (data) {
                console.log('Raw data',data);
                let accType = getFieldValue(data, ACCOUNT_RECORDTYPE); 

                console.log('accType',getFieldValue(data, ACCOUNT_RECORDTYPE)); 

                this.policyNumber = getFieldValue(data, POLICY_ID_FIELD);  
                this.policyId = getFieldValue(data, POLICY_RECORD_ID_FIELD);  
                this.proposalNo = getFieldValue(data, PROPOSAL_No_FIELD); 
                
                console.log('policyNumber',this.policyNumber);
                console.log('policyId',this.policyId);
                console.log('proposalNo',this.proposalNo);
                console.log('accType',accType); 
                
                if(accType == 'Individual'){
                    this.lstAPINames = ['Renewal Check', 'Fitness Assessment'];
                }else{
                    this.lstAPINames = ['Renewal Group Check', 'Fitness Assessment'];
                }
                console.log('lstAPINames',this.lstAPINames[0]); 
                this.getResponseData();
            
        }else{
             this.error = error;
            console.error('Error Getting data from files from database', error);
        }
    } 
                                                     
    getResponseData(){
        console.log('opportunityId',this.recordId); 

        getAPIResponse({ opportunityId : this.recordId, assetId: this.policyId, policyNum : this.policyNumber , proposalNo : this.proposalNo, lstFileSrcAPI : this.lstAPINames }).
        then(result => { 
            if(result){ 
                this.data = result; 
                console.log('API Response',JSON.stringify(result));
            }
        }).catch(error => {
            this.error = error;
            console.error('Error Getting data from files from database', error);
        }); 
    }   
}