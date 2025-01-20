import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getOppRec from '@salesforce/apex/RNWL_RenewalCustomerPolicyInfo.getOppRec';
import getNomineesClaims from '@salesforce/apex/RNWL_RenewalCustomerPolicyInfo.getNomineesClaims';
import getAPIResponse from '@salesforce/apex/RNWL_MemberDetailsController.getAPIResponseDetails';
import getResponseFromFiles from '@salesforce/apex/RNWL_StoredResponseUtility.getResponseFromFiles';//
import toastErrorMsg from '@salesforce/label/c.OppDetailsToastErrorMessage';


export default class RNWL_RenewalPolicyDetails extends LightningElement {
    label = { toastErrorMsg };

    label = {
        toastErrorMsg
    };

    @api recordId;policyId;
    @track account; policy; oppRec; heathRetrn; fitnessData;
    @track areDetailsVisible = false; renewalCheckFlag = false; nominees = []; 
    @track fitnessFlag = false; healthFlag = false;
    @track nomineeContacts; nomineesNames; claimsCounts; isPolicyRenewed;
    @track maturityDate; policyLapseDate; policyLapsed; policyStartDate; dateOfBirth;
    @track polRenewalNoticeDay;graceEndDate;graceStartDate; renStatus;
    @track renewalAPIData; goGreenFlag; isChronic;
    @track autoDebitFlag; sumInsusedEnhancement; 
    @track balanceHR;apiList;error;data;addDownloadStatus;

    @wire(getOppRec, {recordId: '$recordId'})
    record({ error, data}){
        if(data){ 
            this.oppRec = data;
            this.account = data.Account;
            this.policy = data.Policy__r;
            this.policyId = this.oppRec.Policy__c;
            try{
                if(this.account){
                    this.accountId = this.account.Id;
                    if( this.account.RecordType.Name == 'Non-Individual'){
                        this.apiList = ['Renewal Group Check', 'Health Return', 'AppRegDetails'];
                    }
                    else{
                        this.apiList = ['Renewal Check', 'Health Return', 'Fitness Assessment', 'AppRegDetails'];
                    }
                    this.addressString = this.account.BillingStreet ? (this.account.BillingStreet + ', ') : '';
                    this.addressString = this.addressString + (this.account.BillingCity ? (this.account.BillingCity + ', ') : '');
                    this.addressString = this.addressString + (this.account.BillingState ? this.account.BillingState : '');
                    this.addressString = this.addressString + (this.account.BillingPostalCode ? ('-'+this.account.BillingPostalCode) : '');
                    
                    this.addressFlag = this.account.BillingAddress ? true : false;
                    this.dateOfBirth = this.account.PersonBirthdate ? this.getISTDateFormat(new Date(this.account.PersonBirthdate)) : '';
                    this.isChronic = this.account.Is_Chronic__c;
                }
                if(this.policy){
                    this.policyStartDate = this.policy.Issue_Date__c ? this.getISTDateFormat(new Date(this.policy.Issue_Date__c)) : '';
                    this.maturityDate = this.policy.Maturity_Date__c ? this.getISTDateFormat(new Date(this.policy.Maturity_Date__c)) : '';

            if(this.account.RecordType.Name == 'Non-Individual'){
                this.apiList = ['Renewal Group Check', 'Health Return', 'AppRegDetails'];
            }
            else{
                this.apiList = ['Renewal Check', 'Health Return', 'Fitness Assessment', 'AppRegDetails'];
            }

            this.dateOfBirth = this.getISTDateFormat(new Date(this.account.PersonBirthdate));
            this.policyStartDate = this.getISTDateFormat(new Date(this.policy.Issue_Date__c));
            this.maturityDate = this.getISTDateFormat(new Date(this.policy.Maturity_Date__c));

            if(this.policy.Maturity_Date__c != null){
                var matDate = new Date(this.policy.Maturity_Date__c);
                this.policyLapseDate = this.getISTDateFormat(new Date(matDate.setDate(matDate.getDate() + 30)));
            }    
            
            this.graceStartDate = this.getISTDateFormat(new Date(this.oppRec.Grace_Period_Start__c));
            this.graceEndDate = this.getISTDateFormat(new Date(this.oppRec.Grace_Period_End__c));
            this.polRenewalNoticeDay = this.getISTDateFormat(new Date(this.oppRec.Policy_Renewal_Notice_Day__c));   
            this.goGreenFlag = this.policy.GoGreen__c;
            this.isChronic = this.account.Is_Chronic__c;
            this.renStatus = this.oppRec.Status__c == 'Renewed' ? 'Payment Received' : 'In Progress';
            this.isPolicyRenewed = this.oppRec.Status__c == 'Renewed' ? 'Yes' : 'No';

            this.getNomiteeDetails();

            this.getAdditionalData();

        }else{
            this.oppRec = undefined;
            this.error = error; 
        }         
    }

    //////////////////////////////////Imperative methods//////////////////////////////////////////////////

    getAdditionalData(){
        getAPIResponse({ opportunityId : this.recordId, assetId: this.policyId, policyNum : this.oppRec.Proposal_Number__c, proposalNo : this.policy.SerialNumber, lstFileSrcAPI : this.apiList, accountId : this.account.Id }).then(response => {
            if(response){
                this.prepareAdditionalData(response);
            }
        }).catch(error =>{ 
            this.showNotification('error', 'Error!');
        });
    }

    prepareAdditionalData(data){
                let renCheckhArray = [];
                let healthArray = [];
                let fitnessArray = [];
                for (let key in data) {
                    if(key == 'Renewal Check' || key == 'Renewal Group Check'){
                       renCheckhArray = JSON.parse(data[key]).response.policyData;
                        
                    }
                    if(key == 'Health Return'){
                        healthArray = JSON.parse(data[key]).Response;
                        healthArray.forEach((item) => {
                            if(this.account.MMI_Customer_ID__c == item.vchClientCode){
                                this.heathRetrn = item;
                                this.healthFlag = true;
                                this.balanceHR = this.heathRetrn.TotalHealthReturnsTM - this.heathRetrn.TotalHealthReturnsTMBurnt;
                            }
                        })
                    }
                    if(key == 'Fitness Assessment'){
                        fitnessArray = JSON.parse(data[key]).Response;
                        
                        fitnessArray.forEach((item) => {
                            if(this.account.MMI_Customer_ID__c == item.vchClientCode){
                                this.fitnessData = item;   
                                this.fitnessFlag = true;                 
                            }
                        })
                    }
                    if(key == 'AppRegDetails'){
                        this.addDownloadStatus = JSON.parse(data[key]).AppRegDetails.IsAppDowloaded;
                    }
                }

                if(this.apiList.includes('Renewal Check')){                
                    renCheckhArray.forEach((item) => {
                        if(this.oppRec.Policy_Number__c == item.Policy_number){
                            this.renewalAPIData = item;
                            this.autoDebitFlag = this.renewalAPIData.AutoDebitFlag;
                            this.sumInsusedEnhancement = this.renewalAPIData.Upsell_Flag == 'Yes' ? this.renewalAPIData.Upsell_SumInsured : '';
                        }
                    })

                }
                else{
                    renCheckhArray.forEach((item) => {
                        if(this.oppRec.Policy_Number__c == item.Certificate_number){
                            this.renewalAPIData = item;
                            this.autoDebitFlag = this.renewalAPIData.Auto_Debit;
                        }
                    })
                    
                }
                this.renewalCheckFlag = true;
    }    

    getNomiteeDetails(){

        getNomineesClaims({ policyId : this.policyId }).then(result => {

            this.claimsCounts = result.Claims__r.length;
            if(result.PolicyNumber__r.length > 0){
                this.nomineeContacts = result.PolicyNumber__r[0].NomineeContactNumber__c;
                this.nomineesNames = result.PolicyNumber__r[0].Name;
            } 

            result.PolicyNumber__r.forEach((item) => {
                
                if(item.NomineeContactNumber__c && this.nomineeContacts != item.NomineeContactNumber__c){
                    this.nomineeContacts = this.nomineeContacts + ', ' + item.NomineeContactNumber__c;
                }
                if(item.Name && this.nomineesNames != item.Name){
                    this.nomineesNames = this.nomineesNames + ', ' + item.Name;
                }
            });
        }).catch(error => {
            console.error('Error adding contact', error);
        });

    }

    //////////////////////////////////Private methods//////////////////////////////////////////////////

    getISTDateFormat(theDate){
        return String(theDate.getDate()+'/'+(theDate.getMonth() + 1) +'/'+theDate.getFullYear())
    }
    
    showNotification(type, titleMsg){
        const evt = new ShowToastEvent({
            title: titleMsg,
            message: this.label.toastErrorMsg,
            variant: type,
            mode:  'dismissible'
          });
          this.dispatchEvent(evt);
    }

}