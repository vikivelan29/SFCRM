import { LightningElement,wire,api,track } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";  

import POLICY_RECORD_ID_FIELD from "@salesforce/schema/Opportunity.Policy__c";
import PROPOSAL_No_FIELD from "@salesforce/schema/Opportunity.Policy__r.SerialNumber";
import POLICY_ID_FIELD from "@salesforce/schema/Opportunity.Policy_Number__c";
import MASTER_POLICY_ID_FIELD from "@salesforce/schema/Opportunity.Policy__r.MasterPolicyNumber__r.LAN__c";
import ISSUE_DATE_FIELD from "@salesforce/schema/Opportunity.Policy__r.Issue_Date__c";

import getHealthReturnResponse from '@salesforce/apex/RNWL_MemberDetailsController.getHealthReturnResponse';

const fields = [POLICY_RECORD_ID_FIELD, POLICY_ID_FIELD, PROPOSAL_No_FIELD, MASTER_POLICY_ID_FIELD, ISSUE_DATE_FIELD];

const columns = [
    { label: 'Full Name', fieldName: 'Name',wrapText: true},  
    { label: 'Policy No', fieldName: 'vchPolicyNumber', wrapText: true},  
    { label: 'Master Policy No', fieldName: 'MasterPolicyNumber', wrapText: true }, 
    { label: 'Year', fieldName: 'Year',wrapText: true  },
    { label: 'Month', fieldName: 'MonthName', wrapText: true   }, 
    { label: 'HR%', fieldName: 'HRPercentage', wrapText: true }, 
    { label: 'HHS', fieldName: 'HealthyHeartScore', wrapText: true  }, 
    { label: 'AD', fieldName: 'ActiveDays', wrapText: true  },
    { label: 'Total AD', fieldName: 'TotalActiveDays', wrapText: true  }, 
    { label: 'HR Earned', fieldName: 'TotalHealthReturnsTMEarned', wrapText: true }, 
    { label: 'HR Balance', fieldName: 'HRBalance', wrapText: true }, 
    { label: 'HR CF', fieldName: 'HRCFRenewal', wrapText: true  }, 
    { label: 'HR Expiry Date', fieldName: 'HR_Expiry_Date', wrapText: true },  
    { label: 'HHS Start Date', fieldName: 'HHS_Start_Date', wrapText: true}, 
    { label: 'HHS End Date', fieldName: 'HHS_End_Date', wrapText: true }
];  
   
export default class RNWL_HealthReturns extends LightningElement {
    @api recordId;
    @track data;
    @track error;  
    @track noRecordFound; 
    @track message; 
    isLoading = true;
    lstAPINames;
    masterPolicyNum;
    policyId;
    policyNumber;
    proposalNo;
    issueDate;
    columns = columns; 
    activeSectionsMessage = '';
     
    @wire(getRecord, { recordId: '$recordId', fields }) 
    record({ error, data }){
        if (data) {  
                this.policyNumber = getFieldValue(data, POLICY_ID_FIELD);   
                this.policyId = getFieldValue(data, POLICY_RECORD_ID_FIELD);  
                this.proposalNo = getFieldValue(data, PROPOSAL_No_FIELD); 
                this.masterPolicyNum = getFieldValue(data, MASTER_POLICY_ID_FIELD );   
                this.issueDate = getFieldValue(data, ISSUE_DATE_FIELD ); 
                this.lstAPINames = ['Health Return', 'Fitness Assessment']; 
                this.getResponseData(); 
        }
        if(error){
            this.showNotification();
            this.error = error;
            this.message = 'Unexpected Error Occurred ';
            this.noRecordFound = true;  
            this.isLoading = false;
            console.error('Error in standard wire database', error); 
        }
    }
    
    

    showNotification() {
      const evt = new ShowToastEvent({
        title: 'Error',
        message: 'Failed to load Health Returns Data',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(evt);
    }

    getResponseData(){    
        getHealthReturnResponse({ opportunityId : this.recordId, assetId: this.policyId, policyNum : this.policyNumber , proposalNo : this.proposalNo, masterPolicyNum : this.masterPolicyNum, issueDate : this.issueDate, lstFileSrcAPI : this.lstAPINames }).
        then(result => { 
            if(result) {   
                if(result[0].Header == 'No Record Found'){ 
                    this.noRecordFound = true;  
                    this.message = result[0].Header;
                    this.isLoading = false;
                }else if(result[0].Header == 'API Failed') {       
                    this.noRecordFound = true;  
                    this.message = result[0].Header;
                    this.isLoading = false;
                    this.showNotification();
                } 
                if(result[0].Response.length > 0 ){  
                    this.data = result;  
                    this.isLoading = false;
                }    
            }else{
                this.message = 'Unexpected error while getting API data';
                this.noRecordFound = true;  
                this.isLoading = false;
                this.showNotification(); 
            }
        }).catch(error => {
            console.error('Error while getting API data', error);
            this.error = error;
            this.message = 'Unexpected error while getting API data';
            this.noRecordFound = true;  
            this.isLoading = false;
            this.showNotification(); 
        }); 
    }   

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }
}