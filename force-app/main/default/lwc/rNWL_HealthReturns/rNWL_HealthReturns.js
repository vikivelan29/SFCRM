import { LightningElement,wire,api,track } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";  

import POLICY_RECORD_ID_FIELD from "@salesforce/schema/Opportunity.Policy__c";
import PROPOSAL_No_FIELD from "@salesforce/schema/Opportunity.Policy__r.SerialNumber";
import POLICY_ID_FIELD from "@salesforce/schema/Opportunity.Policy_Number__c";
import MASTER_POLICY_ID_FIELD from "@salesforce/schema/Opportunity.Policy__r.MasterPolicyNumber__r.LAN__c";

import getHealthReturnResponse from '@salesforce/apex/RNWL_MemberDetailsController.getHealthReturnResponse';

const fields = [POLICY_RECORD_ID_FIELD, POLICY_ID_FIELD, PROPOSAL_No_FIELD, MASTER_POLICY_ID_FIELD ];

const columns = [
    { label: 'Full Name', fieldName: 'Name',wrapText: true}, // , initialWidth : 150},
    { label: 'Policy No', fieldName: 'vchPolicyNumber', wrapText: true}, // ,initialWidth : 150 },
    { label: 'Master Policy No', fieldName: 'MasterPolicyNumber', wrapText: true }, //,initialWidth : 150 },
    { label: 'Year', fieldName: 'Year',wrapText: true  },
    { label: 'Month', fieldName: 'Month', wrapText: true   }, 
    { label: 'HR%', fieldName: 'HRPercentage', wrapText: true }, 
    { label: 'HHS', fieldName: 'HealthyHeartScore', wrapText: true  }, 
    { label: 'AD', fieldName: 'ActiveDays', wrapText: true  },
    { label: 'Total AD', fieldName: 'TotalActiveDays', wrapText: true  }, 
    { label: 'HR Earned', fieldName: 'TotalHealthReturnsTMEarned', wrapText: true }, 
    { label: 'HR Balance', fieldName: 'HRBalance', wrapText: true }, 
    { label: 'HR CF', fieldName: 'HRCFRenewal', wrapText: true  }, 
    { label: 'HR Expiry Date', fieldName: 'HR_Expiry_Date', wrapText: true }, //,initialWidth : 90 }, 
    { label: 'HHS Start Date', fieldName: 'HHS_Start_Date', wrapText: true}, // ,initialWidth : 90}, 
    { label: 'HHS End Date', fieldName: 'HHS_End_Date', wrapText: true }, // ,initialWidth : 90}    
];  
   
export default class RNWL_HealthReturns extends LightningElement {
    @api recordId;
    @track data;
    @track error; 
    @track success; 
    @track noRecordFound; 
    @track message; 
    lstAPINames;
    masterPolicyNum;
    policyId;
    policyNumber;
    proposalNo;
    columns = columns; 
    activeSectionsMessage = '';
     
    @wire(getRecord, { recordId: '$recordId', fields }) 
    record({ error, data }){
        if (data) { 

                this.policyNumber = getFieldValue(data, POLICY_ID_FIELD);  
                this.policyId = getFieldValue(data, POLICY_RECORD_ID_FIELD);  
                this.proposalNo = getFieldValue(data, PROPOSAL_No_FIELD); 
                this.masterPolicyNum = getFieldValue(data, MASTER_POLICY_ID_FIELD ); 

                console.log('policyNumber',this.policyNumber); 

                this.lstAPINames = ['Health Return', 'Fitness Assessment']; 
                this.getResponseData(); 
            
        }else{
            this.showNotification();
            this.error = error;
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
        console.error('getResponseData ');
        
        getHealthReturnResponse({ opportunityId : this.recordId, assetId: this.policyId, policyNum : this.policyNumber , proposalNo : this.proposalNo, masterPolicyNum : this.masterPolicyNum, lstFileSrcAPI : this.lstAPINames }).
        then(result => { 
            if(result){  
 
                console.error('result ',result); 
                if(result[0].Header == 'No Record Found'){
                    console.log('inside. no record found condition');
                    this.noRecordFound = true;  
                    this.message = result[0].Header;
                }else if(result[0].Header == 'API Failed') {      
                    console.log('inside. API failed condition');
                    this.noRecordFound = true;  
                    this.message = result[0].Header;
                    this.showNotification();
                }
                
                if(result[0].Response.length > 0 ){
                    console.log('inside. success condition');
                    this.data = result; 
                    this.success = true; 
                }                 
            }
        }).catch(error => {
            console.error('Error while getting API data', error);
            this.error = error;
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